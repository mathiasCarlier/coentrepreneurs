# Durcissement sécurité — runbook VPS

Audit du 18/08/2026. Les correctifs de code sont déjà dans le dépôt
(migration 011, `nginx/security-headers.conf`, Edge Functions). Ce document
couvre la partie serveur, qui demande un accès SSH.

Ordre recommandé : **§1 → §2 → §3 → §4**. Le §1 est le plus urgent et le
plus rapide.

---

## Constat de départ

Vérifié depuis l'extérieur le 18/08/2026 :

| Test | Résultat |
| --- | --- |
| `46.225.133.77:5432` | **ouvert**, répond `N` à SSLRequest (pas de TLS) |
| `46.225.133.77:8000` | **ouvert**, sert l'API Supabase complète en HTTP clair |
| `46.225.133.77:8080` | fermé/filtré |
| `46.225.133.77:9001` (MinIO) | fermé/filtré |
| En-têtes HTTPS de `app.coentrepreneurs.fr` | aucun (ni HSTS, ni CSP, ni X-Frame-Options) |
| Lecture anonyme des 7 tables via clé anon | bloquée ✅ |

Mots de passe dans `/home/math/app/.env` : `DB_PASSWORD=mdpmath` et
`MINIO_PASSWORD=mdpmath` — 7 caractères, sans chiffre ni symbole.

---

## §1 — Fermer les ports exposés

### ⚠️ Le piège : ufw ne bloque pas les ports publiés par Docker

Docker insère ses règles dans la chaîne `DOCKER` de `iptables`, évaluée
**avant** celles d'ufw. Un `ufw deny 5432` s'affiche comme actif mais le
port reste joignable depuis Internet. Il faut agir au niveau de Docker, ou
dans la chaîne `DOCKER-USER`.

### Étape 1a — repérer d'où vient la publication

```bash
ssh math@46.225.133.77
docker ps --format 'table {{.Names}}\t{{.Ports}}' | grep -E '5432|8000'
grep -nE '^\s+- .*(5432|8000)' ~/app/supabase-master/docker/docker-compose.yml
```

### Étape 1b — vérifier comment nginx joint l'API *avant* de toucher à Kong

C'est le point qui peut casser le site. Si nginx passe par le réseau Docker
(`proxy_pass http://kong:8000`), on peut retirer la publication sans rien
casser. S'il passe par l'IP de l'hôte, il faut d'abord le rattacher au
réseau Docker de Supabase, sinon le site tombe.

```bash
docker exec app-nginx-1 grep -rn 'proxy_pass' /etc/nginx/conf.d/
docker inspect app-nginx-1 --format '{{json .NetworkSettings.Networks}}' | tr ',' '\n'
```

### Étape 1c — restreindre à la boucle locale

Dans `~/app/supabase-master/docker/docker-compose.yml` :

```yaml
  db:
    ports:
      - "127.0.0.1:${POSTGRES_PORT}:5432"   # au lieu de "${POSTGRES_PORT}:5432"

  kong:
    ports:
      - "127.0.0.1:${KONG_HTTP_PORT}:8000"  # au lieu de "${KONG_HTTP_PORT}:8000"
```

Si l'étape 1b a montré que nginx joint Kong via le réseau Docker, mieux
vaut **supprimer complètement** les deux lignes `ports:` : les conteneurs
communiquent entre eux sans publication sur l'hôte.

```bash
cd ~/app/supabase-master/docker
docker compose up -d db kong
```

### Étape 1d — filet de sécurité ufw

Utile pour tout ce qui n'est pas Docker (services système), mais ne
dispense **pas** de l'étape 1c.

```bash
sudo ufw allow 22/tcp        # ⚠️ AVANT le enable, sous peine de se verrouiller dehors
sudo ufw allow 80,443/tcp
sudo ufw default deny incoming
sudo ufw enable
```

### Étape 1e — vérifier depuis l'extérieur (pas depuis le VPS)

```bash
nc -zv 46.225.133.77 5432    # attendu : refused / timeout
nc -zv 46.225.133.77 8000    # attendu : refused / timeout
curl -I https://app.coentrepreneurs.fr   # attendu : 200, le site répond toujours
```

---

## §2 — Rotation des mots de passe

### ⚠️ Modifier `.env` ne suffit pas

Le mot de passe est stocké **dans la base** (rôle Postgres), pas lu depuis
`.env` à chaque démarrage. Changer le fichier seul casse la connexion des
services sans changer le mot de passe réel. Il faut faire les deux.

```bash
# 1. Sauvegarde avant toute chose
sudo /opt/backup-db.sh

# 2. Générer le nouveau secret
NEW_PW=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32); echo "$NEW_PW"

# 3. Changer le mot de passe DANS Postgres
docker exec -i supabase-db psql -U postgres -c \
  "ALTER USER postgres WITH PASSWORD '$NEW_PW';"

# 4. Répercuter dans .env (POSTGRES_PASSWORD, et DB_PASSWORD si présent)
cd ~/app/supabase-master/docker
cp .env .env.bak-$(date +%F)
sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$NEW_PW|" .env

# 5. Redémarrer la pile
docker compose down && docker compose up -d

# 6. Vérifier que tout est reparti
docker compose ps
curl -I https://app.coentrepreneurs.fr
```

Même opération pour MinIO (`MINIO_ROOT_PASSWORD`), et remplacer
l'utilisateur `admin` par un nom moins devinable.

Vérifier aussi que `~/app/.env` n'est pas lisible par tous :

```bash
chmod 600 ~/app/.env ~/app/supabase-master/docker/.env
```

---

## §3 — En-têtes de sécurité nginx

```bash
# Copier le snippet depuis le poste de dev
scp nginx/security-headers.conf math@46.225.133.77:~/app/nginx/snippets/

# Le monter dans le conteneur (ajouter au volume nginx du docker-compose) :
#   - ./nginx/snippets:/etc/nginx/snippets:ro
# Puis, dans le bloc `server` HTTPS :
#   include /etc/nginx/snippets/security-headers.conf;

docker exec app-nginx-1 nginx -t     # valider AVANT de recharger
docker exec app-nginx-1 nginx -s reload
curl -I https://app.coentrepreneurs.fr | grep -iE 'strict-transport|x-frame|nosniff|referrer'
```

Le fichier contient une CSP en commentaire, à activer en deux temps
(`Report-Only` d'abord) : une CSP trop stricte rend une app Flutter web
blanche sans message d'erreur explicite.

⚠️ HSTS engage les navigateurs pour un an. À n'activer qu'une fois le
certificat Let's Encrypt confirmé stable.

---

## §4 — Migration 011 et dérive du schéma

### Appliquer le durcissement RLS

```bash
scp supabase/migrations/011_security_hardening.sql math@46.225.133.77:/tmp/
ssh math@46.225.133.77
sudo /opt/backup-db.sh                       # toujours avant une migration
docker exec -i supabase-db psql -U postgres -d postgres < /tmp/011_security_hardening.sql
```

Vérification :

```sql
-- Le trigger doit exister et être actif ('O')
SELECT tgname, tgenabled FROM pg_trigger
WHERE tgrelid = 'public.users'::regclass AND NOT tgisinternal;

-- users_update_own doit désormais porter un with_check et TO authenticated
SELECT policyname, cmd, roles, with_check FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'users';
```

Test fonctionnel : depuis un compte **non-admin**, tenter une auto-promotion.
L'UPDATE doit réussir sans que le rôle change.

```sql
UPDATE public.users SET role = 'admin' WHERE id = auth.uid();
SELECT role FROM public.users WHERE id = auth.uid();  -- doit rester inchangé
```

Vérifier ensuite que l'approbation d'un membre par un admin fonctionne
toujours (le trigger laisse passer les admins et le `service_role`).

### Résorber la dérive dépôt / production

Les migrations 001→010 avaient été supprimées du dossier ; elles sont
restaurées depuis l'historique git. Mais la prod a été modifiée directement
via Studio : les policies réelles ne correspondent plus aux fichiers (les
`USING (true)` de la 001 devraient exposer `events` en anonyme, or la prod
le bloque — quelqu'un a durci sans laisser de trace).

Extraire l'état réel et le committer comme référence :

```bash
docker exec supabase-db pg_dump -U postgres --schema-only \
  --schema=public --schema=storage postgres > ~/schema-prod-$(date +%F).sql
```

Puis, depuis le poste de dev :

```bash
scp math@46.225.133.77:~/schema-prod-*.sql supabase/migrations/
```

À comparer avec les migrations numérotées, et à faire converger. Sans ça,
une restauration rejouerait des policies **plus permissives** que la prod.

⚠️ À noter aussi : la migration 008 ne définit des policies que pour le
bucket `events`. Rien pour `messages_attachments`. Si les uploads de pièces
jointes fonctionnent en prod, c'est que des policies y ont été ajoutées à la
main — elles sont donc absentes du dépôt et seraient perdues en cas de
restauration. À récupérer dans le dump ci-dessus.

---

## Reste à traiter (hors périmètre de ce lot)

- **Collision de numérotation** : deux fichiers `007` coexistent
  (`007_indexes.sql` et `007_messages_read_by.sql`). À renuméroter une fois
  la dérive résorbée, pour que l'ordre de rejeu soit déterministe.
- **SMTP** : encore sur InBucket (test). Les emails de reset de mot de passe
  ne partent pas réellement.
- **Pas de CI/CD** : les Edge Functions et migrations se déploient à la main,
  ce qui explique en grande partie la dérive constatée.
