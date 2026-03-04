# Coentrepreneurs

Plateforme collaborative web destinée aux co-entrepreneurs : gestion des adhérents, événements, messages et notifications push.

---

## Fonctionnalités

### Authentification & gestion des accès

- Inscription avec validation des CGU (conditions générales d'utilisation versionnées)
- Connexion email / mot de passe
- Flux d'approbation : nouvel utilisateur → statut `pending` → approbation ou rejet par un admin
- Détection de blocage en temps réel (Supabase Realtime)
- Rôles : `admin`, `adherent`, `invite`

### Espace utilisateur

- Page d'accueil personnalisée selon le rôle et le statut d'approbation
- Écran d'attente pendant la validation du compte
- Formulaire de contact catégorisé (idée, aide, problème, bon plan) avec pièces jointes (photo, fichier, lien)
- Profil et informations professionnelles modifiables (nom, entreprise, compétences, site web, téléphone, adresse, avatar)
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

---

## Stack technique

| Couche | Technologie |
| --- | --- |
| Frontend | Flutter (web uniquement) |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| Navigation | GoRouter v17 |
| State management | Provider (AuthService uniquement) |
| Push notifications | Web Push API (VAPID) + Supabase Edge Functions (Deno) |
| UI | Material 3, Google Fonts Inter |
| Audio | just_audio |
| Fichiers | image_picker, file_picker |

---

## Architecture

```text
lib/
├── main.dart               # Point d'entrée, GoRouter, thèmes
├── models/                 # User, Event, Registration, Invitation, Feedback, CguAcceptance
├── services/               # AuthService, EventService, CguService, NotificationService...
├── pages/                  # Écrans principaux
└── widgets/                # Composants réutilisables

web/
├── index.html              # PWA, manifest, enregistrement push_utils.js
├── push_sw.js              # Service Worker pour les événements push
└── push_utils.js           # Bridge JS → Flutter pour s'abonner/désabonner au push

supabase/
├── migrations/             # Schéma SQL (tables, RLS)
└── functions/              # Edge Functions Deno (send-push, webhooks)
```

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

---

## Lancer le projet

```bash
flutter pub get          # Installer les dépendances
flutter run -d chrome    # Lancer en mode web (développement)
flutter build web        # Build de production
flutter test             # Tests unitaires
flutter analyze          # Analyse statique
```

### Variables de configuration

Le fichier `lib/config/supabase_config.dart` contient l'URL et la clé anonyme Supabase.

Pour les notifications push, définir les secrets Supabase :

```bash
supabase secrets set VAPID_PUBLIC_KEY="<clé-publique>"
supabase secrets set VAPID_PRIVATE_KEY="<clé-privée>"
supabase secrets set VAPID_SUBJECT="mailto:admin@coentrepreneurs.com"
```

Et remplacer `_vapidPublicKey` dans `lib/services/notification_service.dart`.

---

## Flux d'approbation utilisateur

```text
Inscription → approval_status: pending
  ↓ (admin approuve)
approval_status: approved → accès complet
  ↓ (ou admin rejette)
approval_status: rejected → accès refusé
```

---

## Déploiement des Edge Functions

```bash
supabase functions deploy send-push
supabase functions deploy webhook-user-signup
supabase functions deploy webhook-user-approved
supabase functions deploy webhook-event-created
```

Puis configurer 3 webhooks dans le dashboard Supabase (Database > Webhooks) :

| Webhook | Table | Événement | Fonction |
| --- | --- | --- | --- |
| push_new_signup | users | INSERT | webhook-user-signup |
| push_user_status | users | UPDATE | webhook-user-approved |
| push_new_event | events | INSERT | webhook-event-created |
