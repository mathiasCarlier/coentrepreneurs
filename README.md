# Coentrepreneurs

Plateforme collaborative web destinée aux co-entrepreneurs : gestion des adhérents, événements, messages et notifications push.

Production : **https://app.coentrepreneurs.fr**

---

## Fonctionnalités

### Authentification & gestion des accès

- Inscription avec validation des CGU (conditions générales d'utilisation versionnées)
- Connexion email / mot de passe, réinitialisation de mot de passe (flux PKCE)
- Flux d'approbation : nouvel utilisateur → statut `pending` → approbation ou rejet par un admin
- Détection de blocage en temps réel (Supabase Realtime)
- Rôles : `admin`, `adherent`, `invite`

### Espace utilisateur

- Page d'accueil personnalisée selon le rôle et le statut d'approbation
- Écran d'attente pendant la validation du compte
- Formulaire de contact catégorisé (idée, aide, problème, bon plan) avec pièces jointes (photo, fichier, lien)
- Profil et informations professionnelles modifiables (nom, entreprise, compétences, site web, téléphone, adresse, avatar)
- Passions, date d'adhésion, parrainage
- Changement de mot de passe

### Annuaire des adhérents

- Liste des membres ayant activé le partage de leurs informations professionnelles
- Actions directes : appel, email, site web

### Événements

- Calendrier des rencontres à venir
- Inscription et confirmation de présence
- Historique de tous les événements
- Formulaire de feedback post-événement avec notation

### Espace admin

- **Gestion des adhésions** : approbation / rejet des nouvelles demandes, liste des membres récents
- **Gestion des utilisateurs** : changement de rôle, blocage / déblocage
- **Gestion des événements** : création, modification, cycle de vie (pending → started → finished), upload de médias, résumé post-événement
- **Messages** : consultation, lecture, publication ou suppression des messages des adhérents

### Notifications

- Badge en temps réel sur l'icône de notifications (nouvelles demandes, nouveaux événements, nouveaux messages)
- **Notifications push navigateur (VAPID)** : sans Firebase, via le standard Web Push API
  - L'admin reçoit une notification quand un utilisateur s'inscrit
  - L'utilisateur reçoit une notification quand son compte est approuvé ou rejeté
  - Tous les adhérents reçoivent une notification lors de la création d'un événement
  - Un email part vers les admins à chaque nouveau message (via Resend)
  - Digest quotidien des notifications non lues

---

## Stack technique

| Couche | Technologie |
| --- | --- |
| Frontend | Flutter (web uniquement) |
| Backend | Supabase **auto-hébergé** (PostgreSQL + Auth + Storage + Realtime + Edge Functions) |
| Navigation | GoRouter v17 |
| State management | Provider (AuthService uniquement) |
| Push notifications | Web Push API (VAPID) + Edge Functions Deno |
| Emails transactionnels | Resend |
| Monitoring | Sentry (`sentry_flutter`, inactif en debug) |
| UI | Material 3, Google Fonts Inter, `table_calendar`, `badges`, `flutter_markdown_plus` |
| Audio | `just_audio` |
| Fichiers | `image_picker`, `file_picker` |

---

## Infrastructure

Supabase n'est **pas** hébergé chez Supabase Cloud : la pile tourne en Docker sur un VPS.

| Élément | Valeur |
| --- | --- |
| VPS | `46.225.133.77` |
| Domaine | `https://app.coentrepreneurs.fr` (Let's Encrypt) |
| Reverse proxy | conteneur `app-nginx-1` (⚠️ pas le nginx système) |
| API Supabase | `https://app.coentrepreneurs.fr/supabase-api` |
| Pile Supabase | `/home/math/app/supabase-master/docker/` |
| Edge Functions | `/home/math/app/supabase-master/docker/volumes/functions/` |
| Conteneur DB | `supabase-db` |
| Backup DB | cron quotidien 2 h, `/opt/backup-db.sh`, rétention 7 jours dans `/backups/` |

---

## Architecture

```text
lib/
├── main.dart               # Point d'entrée, GoRouter, thèmes, init Sentry
├── router_utils.dart       # computeRedirect() — logique de redirection (testée)
├── supabase_config.dart    # URL + clé anonyme Supabase
├── models/                 # User, Event, Registration, Invitation, Feedback, CguAcceptance
├── services/               # AuthService, EventService, CguService, NotificationService...
├── pages/                  # Écrans principaux
└── widgets/                # Composants réutilisables

web/
├── index.html              # PWA, manifest, enregistrement push_utils.js
├── push_sw.js              # Service Worker pour les événements push
└── push_utils.js           # Bridge JS → Flutter pour s'abonner/désabonner au push

supabase/
├── migrations/             # Schéma SQL (tables, RLS, triggers)
└── functions/              # Edge Functions Deno

nginx/
└── security-headers.conf   # En-têtes de sécurité à inclure dans le vhost
```

Les services sont instanciés directement dans les pages (pas d'injection de
dépendances) ; seul `AuthService` passe par Provider.

### Tables Supabase

| Table | Rôle |
| --- | --- |
| `users` | Profils utilisateurs, rôles, statut d'approbation |
| `events` | Données des événements |
| `registrations` | Inscriptions aux événements |
| `invitations` | Invitations aux événements |
| `feedbacks` | Retours post-événement |
| `cgu_acceptances` | Acceptations des CGU par version |
| `messages` | Messages de contact des adhérents |
| `push_subscriptions` | Souscriptions push navigateur (VAPID) |

### Buckets Storage

| Bucket | Accès | Usage |
| --- | --- | --- |
| `events` | public | Images et fichiers des événements |
| `messages_attachments` | privé (URLs signées) | Pièces jointes des messages |

### Migrations

Fichiers dans `supabase/migrations/`, à rejouer dans l'ordre numérique.

> ⚠️ **Le schéma déployé a dérivé de ces fichiers** : des policies ont été
> modifiées directement dans Studio sans être reportées ici. Lire
> [docs/SECURITE.md](docs/SECURITE.md) §4 avant de s'appuyer dessus pour une
> restauration. Deux fichiers portent par ailleurs le numéro `007`.

---

## Lancer le projet

```bash
flutter pub get          # Installer les dépendances
flutter run -d chrome    # Lancer en mode web (développement)
flutter build web        # Build de production
flutter test             # Tests unitaires
flutter analyze          # Analyse statique
```

### Configuration

| Quoi | Où |
| --- | --- |
| URL + clé anonyme Supabase | `lib/supabase_config.dart` |
| Clé VAPID **publique** (client) | `lib/services/notification_service_web.dart` |
| DSN Sentry | passé via `--dart-define`, voir `lib/main.dart` |

La clé anonyme et la clé VAPID publique sont publiques par conception : elles
sont embarquées dans le bundle web. La sécurité repose sur les policies RLS,
jamais sur le secret de ces clés.

Les secrets côté serveur (`VAPID_PRIVATE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
`RESEND_API_KEY`) vivent dans le `.env` de la pile Docker sur le VPS et ne
doivent jamais apparaître dans le dépôt ni dans le code client.

---

## Flux d'approbation utilisateur

```text
Inscription → approval_status: pending
  ↓ (admin approuve)
approval_status: approved → accès complet
  ↓ (ou admin rejette)
approval_status: rejected → accès refusé
```

Les colonnes `role`, `blocked`, `approval_status` et `approved_at` sont
protégées en base par un trigger (migration 011) : seuls un admin ou le
`service_role` peuvent les modifier.

---

## Déploiement

Tout est manuel (pas de CI/CD à ce jour).

### Application web

```bash
./deploy.sh    # flutter build web --release + rsync vers math@46.225.133.77:~/app/web/
```

### Edge Functions

Supabase étant auto-hébergé, la CLI `supabase functions deploy` ne s'applique
pas : les fonctions se copient dans le volume monté par le conteneur.

```bash
scp -r supabase/functions/<nom> \
  math@46.225.133.77:/home/math/app/supabase-master/docker/volumes/functions/
ssh math@46.225.133.77 'docker restart supabase-edge-functions'
```

| Fonction | Déclencheur | Rôle |
| --- | --- | --- |
| `send-push` | HTTP POST | Envoi des notifications push (par `user_ids` ou par rôle) |
| `webhook-user-signup` | DB webhook INSERT `users` | Prévient les admins d'une nouvelle demande |
| `webhook-user-approved` | DB webhook UPDATE `users` | Prévient l'utilisateur de l'approbation / du rejet |
| `webhook-event-created` | DB webhook INSERT `events` | Prévient les adhérents d'un nouvel événement |
| `webhook-new-message` | DB webhook INSERT `messages` | Envoie un email aux admins via Resend |
| `daily-digest` | cron / HTTP POST | Digest quotidien des notifications non lues |

Les six fonctions exigent l'en-tête `Authorization: Bearer <service_role_key>`
et refusent toute requête si la clé n'est pas configurée (fail-closed).

### Migrations

```bash
scp supabase/migrations/<fichier>.sql math@46.225.133.77:/tmp/
ssh math@46.225.133.77
sudo /opt/backup-db.sh    # toujours sauvegarder avant
docker exec -i supabase-db psql -U postgres -d postgres < /tmp/<fichier>.sql
```

---

## Sécurité

Le modèle de sécurité repose sur les **policies RLS** de PostgreSQL : le client
Flutter parle directement à PostgREST avec la clé anonyme, et c'est la base qui
arbitre chaque lecture et chaque écriture. Toute nouvelle table doit donc avoir
`ENABLE ROW LEVEL SECURITY` et des policies explicites, sans quoi elle est soit
inaccessible, soit ouverte à tous.

Audit complet, correctifs et runbook de durcissement VPS :
**[docs/SECURITE.md](docs/SECURITE.md)**.

Procédure de restauration : [docs/DISASTER_RECOVERY.md](docs/DISASTER_RECOVERY.md).
