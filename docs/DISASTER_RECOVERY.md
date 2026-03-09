# Guide de reprise après perte du serveur

## Ce dont tu as besoin avant de commencer

- Accès à ton nouveau VPS (Ubuntu 22.04 recommandé)
- Le fichier `.env` de Supabase **(critique — à sauvegarder localement maintenant)**
- Le fichier `docker-compose.yml` **(idem)**
- Un backup `.sql.gz` de la base de données
- Le repo Git du projet Flutter

> **Action immédiate :** copie `.env` et `docker-compose.yml` du VPS sur ton PC local dès aujourd'hui.
> ```bash
> scp math@46.225.133.77:/home/math/app/.env ./backups-config/
> scp math@46.225.133.77:/home/math/app/docker-compose.yml ./backups-config/
> ```

---

## Étape 1 — Préparer le nouveau VPS

```bash
# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer Docker
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER
newgrp docker

# Installer Docker Compose
sudo apt install docker-compose-plugin -y

# Vérifier
docker --version
docker compose version
```

---

## Étape 2 — Recréer la structure Supabase

```bash
# Créer les dossiers
mkdir -p /home/math/app/volumes/functions
mkdir -p /home/math/app/volumes/storage
mkdir -p /backups

# Copier docker-compose.yml et .env depuis ta sauvegarde locale
# (via scp ou copier-coller manuellement)
```

---

## Étape 3 — Copier les Edge Functions

Depuis ton PC, copier les fonctions sur le nouveau VPS :

```bash
scp -r supabase/functions/* math@NOUVEAU_IP:/home/math/app/volumes/functions/
```

Les fonctions concernées :
- `send-push/`
- `webhook-user-signup/`
- `webhook-user-approved/`
- `webhook-event-created/`

---

## Étape 4 — Démarrer Supabase

```bash
cd /home/math/app
docker compose up -d

# Attendre ~30 secondes puis vérifier que tout est up
docker compose ps
```

Tous les conteneurs doivent être `healthy` ou `running`.

---

## Étape 5 — Restaurer la base de données

```bash
# Copier le backup sur le nouveau VPS
scp db_YYYYMMDD_HHMM.sql.gz user@NOUVEAU_IP:/backups/

# Restaurer
gunzip -c /backups/db_YYYYMMDD_HHMM.sql.gz | docker exec -i supabase-db psql -U postgres postgres
```

> Si la DB n'est pas vide, vider avant de restaurer :
> ```bash
> docker exec -i supabase-db psql -U postgres -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" postgres
> ```

---

## Étape 6 — Vérifier les migrations manquantes

Si le backup est ancien, rejouer les migrations manquantes :

```bash
# Depuis ton PC
cat supabase/migrations/001_initial_schema.sql | docker exec -i supabase-db psql -U postgres postgres
cat supabase/migrations/002_push_subscriptions.sql | docker exec -i supabase-db psql -U postgres postgres
cat supabase/migrations/003_realtime_users.sql | docker exec -i supabase-db psql -U postgres postgres
```

---

## Étape 7 — Configurer HTTPS avec Let's Encrypt

```bash
# Installer Certbot
sudo apt install certbot -y

# Obtenir le certificat (nginx doit être arrêté)
sudo certbot certonly --standalone -d app.coentrepreneurs.fr

# Les certificats sont dans :
# /etc/letsencrypt/live/app.coentrepreneurs.fr/fullchain.pem
# /etc/letsencrypt/live/app.coentrepreneurs.fr/privkey.pem
```

Mettre à jour le fichier nginx dans `docker-compose.yml` pour pointer vers ces certificats.

---

## Étape 8 — Reconfigurer les Webhooks

Via Supabase Studio (`http://NOUVEAU_IP:8080`) ou via SQL :

```sql
-- Mettre à jour l'URL des webhooks avec la nouvelle IP ou le domaine
-- Voir supabase/migrations/001_initial_schema.sql section webhooks
```

---

## Étape 9 — Mettre à jour l'app Flutter

Dans `lib/core/supabase_config.dart`, mettre à jour si l'IP ou le domaine a changé :

```dart
static const String supabaseUrl = 'https://app.coentrepreneurs.fr';
```

Puis rebuild et redéployer l'app web :

```bash
flutter build web
# Copier build/web/ sur le serveur
```

---

## Étape 10 — Reconfigurer le backup automatique

```bash
sudo mkdir -p /backups
sudo tee /opt/backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M)
docker exec supabase-db pg_dump -U postgres postgres | gzip > /backups/db_$DATE.sql.gz
find /backups -name "*.sql.gz" -mtime +7 -delete
EOF
sudo chmod +x /opt/backup-db.sh
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /opt/backup-db.sh") | sudo crontab -
```

---

## Checklist finale

- [ ] `docker compose ps` → tous les conteneurs up
- [ ] Supabase Studio accessible
- [ ] Auth fonctionne (login dans l'app)
- [ ] Données présentes (utilisateurs, événements)
- [ ] Upload fichiers fonctionne (Storage)
- [ ] Notifications push fonctionnent
- [ ] Backup cron recréé

---

## Fichiers critiques à sauvegarder localement DÈS MAINTENANT

| Fichier | Emplacement VPS | Contenu critique |
|---|---|---|
| `.env` | `/home/math/app/.env` | Clés VAPID, JWT secret, SMTP |
| `docker-compose.yml` | `/home/math/app/docker-compose.yml` | Config complète |
| Backup DB | `/backups/*.sql.gz` | Toutes les données |
