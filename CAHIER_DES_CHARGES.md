# Cahier des Charges — Application Coentrepreneurs
**Document rétroactif — état de l'application au 09 mars 2026**

---

## Sommaire

1. [Présentation du projet](#1-présentation-du-projet)
2. [Contexte et objectifs](#2-contexte-et-objectifs)
3. [Périmètre fonctionnel](#3-périmètre-fonctionnel)
4. [Rôles et droits utilisateurs](#4-rôles-et-droits-utilisateurs)
5. [Modules fonctionnels détaillés](#5-modules-fonctionnels-détaillés)
6. [Architecture technique](#6-architecture-technique)
7. [Base de données](#7-base-de-données)
8. [Notifications et temps réel](#8-notifications-et-temps-réel)
9. [Sécurité et conformité](#9-sécurité-et-conformité)
10. [Infrastructure et déploiement](#10-infrastructure-et-déploiement)
11. [Contraintes et choix techniques](#11-contraintes-et-choix-techniques)

---

## 1. Présentation du projet

| Champ | Détail |
|---|---|
| **Nom de l'application** | Coentrepreneurs |
| **Type** | Application web progressive (PWA) |
| **Public cible** | Membres de l'association Coentrepreneurs |
| **Langue** | Français intégralement |
| **URL de production** | https://app.coentrepreneurs.fr |
| **Environnement** | Self-hosted VPS (Supabase + Flutter Web) |

L'application Coentrepreneurs est une plateforme numérique privée dédiée aux membres de l'association. Elle centralise la gestion des événements, l'annuaire des membres, la messagerie interne, et la vie associative. Elle est accessible via navigateur web sur ordinateur et mobile, avec une expérience installable (PWA).

---

## 2. Contexte et objectifs

### 2.1 Contexte

L'association Coentrepreneurs réunit des entrepreneurs qui se retrouvent régulièrement pour partager expériences, connaissances et opportunités. Avant cette application, les échanges et la logistique des événements étaient gérés manuellement (emails, tableurs, messageries tierces).

### 2.2 Objectifs

- Disposer d'un espace numérique propre à l'association, sans dépendance à des outils grand public
- Centraliser la gestion des adhérents (inscription, validation, profils)
- Automatiser la logistique des événements (inscriptions, présences, repas, retours)
- Faciliter le réseautage entre membres (annuaire professionnel)
- Outiller les administrateurs (tableau de bord, approbations, statistiques)
- Garantir la confidentialité des données des membres

---

## 3. Périmètre fonctionnel

### Modules réalisés

| Module | Description |
|---|---|
| Authentification | Connexion, inscription, réinitialisation mot de passe |
| Gestion des membres | Approbation, blocage, profils complets |
| Événements | CRUD complet, cycle de vie, inscriptions, présences |
| Collation | Gestion du repas post-événement |
| Feedback | Collecte d'avis après événement |
| Invitations | Invitation de membres à un événement |
| Annuaire | Répertoire dynamique des membres |
| Messagerie interne | Formulaire de contact et messages aux admins |
| Notifications | Notifications push (web) + centre de notifications in-app |
| CGU | Affichage et acceptation des Conditions Générales d'Utilisation |
| FAQ | Page de questions fréquentes |
| Administration | Gestion utilisateurs, événements, messages |
| Profil | Édition des informations personnelles et professionnelles |

---

## 4. Rôles et droits utilisateurs

L'application distingue trois niveaux d'accès :

### 4.1 `admin`

- Accès complet à toutes les fonctionnalités
- Création, modification, suppression d'événements
- Approbation ou rejet des demandes d'adhésion
- Blocage d'un membre (accès immédiatement révoqué)
- Lecture et gestion de tous les messages internes
- Réception des notifications push lors d'une nouvelle demande d'adhésion
- Accès aux statistiques des événements
- Modification du profil de tout utilisateur
- Gestion des collations (menus)

### 4.2 `adherent`

- Accès à l'ensemble des fonctionnalités membres
- Inscription et désinscription aux événements
- Confirmation de présence (lors d'un événement en cours)
- Participation à la collation
- Envoi et réception d'invitations à un événement
- Dépôt d'un feedback après événement
- Accès à l'annuaire des membres
- Réception des notifications push lors d'un nouvel événement
- Réception d'une notification push lors de l'approbation du compte

### 4.3 `invite`

- Accès restreint (rôle transitoire)
- Peut consulter les événements
- Ne peut pas accéder à l'annuaire complet
- Ne reçoit pas les notifications d'événements

### 4.4 Workflow d'approbation

```
Inscription (signup) → statut "pending"
       ↓
  Notification admin
       ↓
Admin approuve / rejette
       ↓
Notification à l'utilisateur (approuvé ou refusé)
       ↓
Si approuvé → rôle "adherent", accès complet
```

Un compte bloqué est déconnecté immédiatement via un listener Realtime.

---

## 5. Modules fonctionnels détaillés

### 5.1 Authentification

**Inscription (`/signup`)**
- Champs : prénom, nom, email, téléphone, mot de passe
- Validation côté client
- Création d'un profil en base avec statut `pending`
- Message d'attente affiché jusqu'à approbation

**Connexion (`/login`)**
- Email + mot de passe
- Messages d'erreur en français (email inconnu, mauvais mot de passe, compte désactivé, etc.)
- Redirection automatique vers `/home` si déjà connecté

**Réinitialisation du mot de passe**
- Envoi d'un email de réinitialisation via Supabase Auth

**Déconnexion**
- Disponible depuis la page Paramètres
- Nettoyage de la session locale

---

### 5.2 Page d'accueil (`/home`)

- Affichage des prochains événements (à venir)
- Accès rapide aux sections principales (événements, annuaire, notifications, paramètres)
- Initialisation des notifications push (pour les membres approuvés)
- Affichage de la dialog CGU si l'utilisateur n'a pas encore accepté la version en vigueur
- Détection temps réel du blocage compte (déconnexion automatique)

---

### 5.3 Gestion des événements

#### Cycle de vie d'un événement

```
pending (à venir) → started (en cours) → finished (terminé)
```

#### Données d'un événement

| Champ | Type | Description |
|---|---|---|
| Date | DateTime | Date et heure de l'événement |
| Thème | Texte | Sujet de la réunion |
| Intervenant | Texte | Nom du présentateur |
| Entreprise | Texte | Structure de l'intervenant |
| Lieu | Texte | Adresse physique |
| Participants max | Entier | Capacité maximale |
| Statut | Enum | pending / started / finished |
| Résumé | Texte (optionnel) | Bref résumé |
| Description | Texte (optionnel) | Description longue |
| Lien | URL (optionnel) | Lien associé |
| Image | URL (optionnel) | Photo/visuel |
| Fichier | URL + nom (optionnel) | Document joint |
| Menu collation | Texte (optionnel) | Description du repas |

#### Vue membre (`/events`)

- Liste des événements avec filtrage / tri
- Carte événement affichant : date, thème, intervenant, lieu, taux d'inscription
- Bouton d'inscription / désinscription
- Bouton de confirmation de présence (si événement `started`)
- Badge de statut de présence (inscrit / confirmé / décliné)
- Participation à la collation (si menu disponible)
- Partage du lien événement

#### Vue admin (`/admin/events`)

- CRUD complet (créer, modifier, supprimer un événement)
- Changement de statut (démarrer / terminer)
- Affichage de la liste des inscrits, confirmés, déclinés avec contacts
- Gestion du menu collation + liste des participants collation
- Section feedback post-événement avec note moyenne et avis individuels
- Gestion des invitations pour chaque événement

---

### 5.4 Collation

La collation est le repas organisé après certains événements.

- L'administrateur renseigne un texte de menu dans l'événement
- Chaque membre inscrit peut confirmer ou annuler sa participation au repas via une dialog dédiée
- L'admin voit la liste des participants à la collation

---

### 5.5 Feedback post-événement

Après la clôture d'un événement (`finished`) :

- Un prompt apparaît aux membres ayant confirmé leur présence
- Le formulaire de feedback collecte :
  - Ce que l'utilisateur a apprécié (texte libre)
  - Note de satisfaction (0 à 10)
  - Ce que l'utilisateur a appris (texte libre)
- Un seul feedback par utilisateur par événement (mise à jour possible)
- L'admin voit un récapitulatif : note moyenne, nombre d'avis, avis individuels

---

### 5.6 Invitations

- Un membre peut inviter un contact externe à un événement
- Champs : email, prénom, nom de la personne invitée
- L'invitation est enregistrée avec statut `pending`
- L'invité peut accepter ou décliner
- En cas d'acceptation, l'invité est automatiquement inscrit à l'événement
- L'admin peut gérer les invitations de tout événement

---

### 5.7 Annuaire des membres (`/directory`)

- Liste en temps réel de tous les membres approuvés (Supabase Realtime)
- Chaque fiche membre affiche (si le membre a activé le partage pro) :
  - Prénom, nom, photo de profil
  - Entreprise, compétences, adresse professionnelle, site web
- Recherche textuelle
- Filtrage par critères
- Respecte le choix de confidentialité de chaque membre (`share_pro_info`)

---

### 5.8 Messagerie interne (`/messages`)

- Formulaire de contact accessible depuis l'app
- Catégories de messages définissables
- Possibilité de joindre un lien, une image, ou un fichier
- Messages visibles uniquement par les administrateurs
- Marquage lu/non-lu, publication (rendre visible aux membres)
- Notifications push aux admins lors d'un nouveau message

---

### 5.9 Centre de notifications (`/notifications`)

Trois onglets :

| Onglet | Contenu | Visible par |
|---|---|---|
| Adhésions | Demandes en attente + membres récemment approuvés | Admin |
| Événements | Notifications liées aux événements | Tous |
| Messages | Messages reçus du formulaire de contact | Admin |

- Compteur de non-lus sur chaque onglet (badges)
- Marquage automatique comme lu au clic
- Suivi via les colonnes `read_notification_event_ids`, `read_notification_message_ids`, `read_new_member_ids` dans le profil utilisateur

---

### 5.10 Profil et paramètres (`/settings`)

**Informations personnelles**
- Prénom, nom, email, téléphone
- Photo de profil (upload vers Supabase Storage)
- Date d'adhésion (`member_since`)
- Passions / centres d'intérêt (`passions`)

**Informations professionnelles**
- Nom de l'entreprise
- Compétences
- Adresse professionnelle
- Site web
- Choix de partage dans l'annuaire (`share_pro_info`)

**Gestion du compte**
- Déconnexion
- (Admin) Accès à la gestion des utilisateurs : approbation / rejet / blocage

---

### 5.11 Conditions Générales d'Utilisation (CGU)

- Texte complet des CGU intégré dans l'application (10 sections, en français)
- Version courante : `1.0`
- À la première connexion post-approbation, une dialog s'affiche
- L'acceptation est enregistrée en base (`cgu_acceptances`) avec horodatage
- Sans acceptation, l'accès aux fonctionnalités est limité
- Système versionnée : une nouvelle version de CGU déclenche une nouvelle demande d'acceptation

---

### 5.12 FAQ (`/faq`)

- Page de questions/réponses fréquentes
- Contenu rendu en Markdown

---

## 6. Architecture technique

### 6.1 Stack technologique

| Composant | Technologie | Version |
|---|---|---|
| Frontend | Flutter (Web/PWA) | SDK Flutter stable |
| Backend | Supabase (self-hosted) | — |
| Base de données | PostgreSQL (via Supabase) | — |
| Authentification | Supabase Auth | — |
| Stockage fichiers | Supabase Storage | — |
| Temps réel | Supabase Realtime | — |
| Fonctions serverless | Supabase Edge Functions (Deno/TypeScript) | — |
| Navigation | GoRouter | v17 |
| État global | Provider | v6 |
| Thème / typographie | Material 3 + Google Fonts Inter | — |
| PWA / Push | Service Worker + VAPID (web-push) | — |

### 6.2 Organisation du code Flutter

```
lib/
├── main.dart                 # Point d'entrée, GoRouter, thème
├── supabase_config.dart      # URL et clé Supabase
├── router_utils.dart         # Logique de redirection (testée)
├── models/                   # Modèles de données (toMap, fromMap, copyWith)
│   ├── user.dart
│   ├── event.dart
│   ├── feedback.dart
│   ├── invitation.dart
│   └── cgu_acceptance.dart
├── services/                 # Couche d'accès aux données Supabase
│   ├── auth_service.dart
│   ├── event_service.dart
│   ├── registration_service.dart
│   ├── feedback_service.dart
│   ├── invitation_service.dart
│   ├── cgu_service.dart
│   ├── notification_service.dart
│   ├── storage_service.dart
│   └── location_service.dart
├── pages/                    # Écrans complets
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── home_page.dart
│   ├── settings_page.dart
│   ├── all_events_page.dart
│   ├── admin_events_page.dart
│   ├── directory_page_dynamic.dart
│   ├── notifications_page.dart
│   ├── messages_page.dart
│   └── faq_page.dart
└── widgets/                  # Composants réutilisables
    ├── event_card_avec_inscription.dart
    ├── event_guests_section.dart
    ├── event_feedback_section.dart
    ├── cgu_acceptance_dialog.dart
    ├── feedback_dialog.dart
    ├── feedback_prompt.dart
    ├── invitation_dialog.dart
    ├── collation_dialog.dart
    └── fullscreen_image_viewer.dart
```

### 6.3 Principes d'architecture

- **Services** : un service par domaine métier, exposant des méthodes `Future` et `Stream`
- **Modèles** : sérialisation `toMap()` / `fromMap()` pour Supabase ; `copyWith()` pour les mises à jour
- **Pages** : instancient les services directement (pas de conteneur DI)
- **État global** : Provider utilisé uniquement pour `AuthService` (singleton)
- **État local** : `setState()` dans les pages, pas de gestion d'état complexe
- **Navigation** : GoRouter v17 avec `GoRouterRefreshStream` sur `authStateChanges`
- **Sécurité DB** : RLS (Row Level Security) PostgreSQL appliquée sur toutes les tables

---

## 7. Base de données

### 7.1 Schéma des tables

#### `public.users`
Extension du profil Supabase Auth.

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID (PK, FK auth.users) | Identifiant unique |
| `email` | TEXT | Email |
| `nom` | TEXT | Nom de famille |
| `prenom` | TEXT | Prénom |
| `phone` | TEXT | Téléphone |
| `photo_url` | TEXT | URL de la photo de profil |
| `role` | TEXT | `admin` / `adherent` / `invite` |
| `company_name` | TEXT | Entreprise |
| `skills` | TEXT | Compétences |
| `professional_address` | TEXT | Adresse pro |
| `website` | TEXT | Site web |
| `share_pro_info` | BOOLEAN | Partage dans l'annuaire |
| `blocked` | BOOLEAN | Compte bloqué |
| `approval_status` | TEXT | `pending` / `approved` / `rejected` |
| `read_notification_event_ids` | TEXT[] | IDs événements lus |
| `read_notification_message_ids` | TEXT[] | IDs messages lus |
| `read_new_member_ids` | TEXT[] | IDs membres vus |
| `member_since` | DATE | Date d'adhésion |
| `passions` | TEXT | Centres d'intérêt |
| `created_at` | TIMESTAMPTZ | Création du compte |
| `approved_at` | TIMESTAMPTZ | Date d'approbation |

**Trigger** : `handle_new_user()` crée une ligne minimale à l'inscription.
**Realtime** : REPLICA IDENTITY FULL activé pour les mises à jour live de l'annuaire.

---

#### `public.events`

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID (PK) | |
| `date` | TIMESTAMPTZ | Date et heure |
| `theme` | TEXT | Thème |
| `intervenant` | TEXT | Nom de l'intervenant |
| `entreprise` | TEXT | Entreprise de l'intervenant |
| `lieu` | TEXT | Lieu |
| `max_participants` | INTEGER | Capacité maximale |
| `status` | TEXT | `pending` / `started` / `finished` |
| `summary` | TEXT | Résumé (optionnel) |
| `description` | TEXT | Description (optionnel) |
| `link_url` | TEXT | Lien (optionnel) |
| `image_url` | TEXT | Image (optionnel) |
| `file_url` | TEXT | Fichier joint (optionnel) |
| `file_name` | TEXT | Nom du fichier |
| `collation_menu_text` | TEXT | Menu collation (optionnel) |
| `created_at` | TIMESTAMPTZ | |

**RLS** : SELECT public, INSERT/UPDATE/DELETE admin uniquement.

---

#### `public.registrations`

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID (PK) | |
| `event_id` | UUID (FK events) | |
| `user_id` | UUID (FK users) | |
| `status` | TEXT | `registered` / `confirmed` / `declined` |
| `has_collation` | BOOLEAN | Participation au repas |
| `created_at` | TIMESTAMPTZ | |
| `responded_at` | TIMESTAMPTZ | Date de réponse |

Contrainte UNIQUE sur `(event_id, user_id)`.

---

#### `public.invitations`

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID (PK) | |
| `event_id` | UUID (FK events) | |
| `invited_by_user_id` | UUID (FK users) | Expéditeur |
| `invited_user_email` | TEXT | Email invité |
| `invited_user_prenom` | TEXT | Prénom invité |
| `invited_user_nom` | TEXT | Nom invité |
| `status` | TEXT | `pending` / `accepted` / `declined` |
| `created_at` | TIMESTAMPTZ | |
| `responded_at` | TIMESTAMPTZ | |

---

#### `public.feedbacks`

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID (PK) | |
| `event_id` | UUID (FK events) | |
| `user_id` | UUID (FK users) | |
| `user_email` | TEXT | |
| `user_prenom` | TEXT | |
| `user_nom` | TEXT | |
| `what_you_liked` | TEXT | Ce qui a été apprécié |
| `what_you_learned` | TEXT | Ce qui a été appris |
| `rating` | INTEGER (0-10) | Note de satisfaction |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | |

Contrainte UNIQUE sur `(event_id, user_id)`.

---

#### `public.cgu_acceptances`

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID (PK) | |
| `user_id` | UUID (FK users) | |
| `has_accepted` | BOOLEAN | |
| `accepted_date` | TEXT | Date d'acceptation |
| `cgu_version` | TEXT | Version des CGU (`1.0`) |
| `created_at` | TIMESTAMPTZ | |

Contrainte UNIQUE sur `(user_id, cgu_version)`.

---

#### `public.messages`

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID (PK) | |
| `user_id` | UUID | Auteur |
| `user_name` | TEXT | Nom affiché |
| `user_email` | TEXT | Email auteur |
| `user_role` | TEXT | Rôle au moment de l'envoi |
| `category` | TEXT | Catégorie du message |
| `message` | TEXT | Contenu |
| `read` | BOOLEAN | Lu par un admin |
| `published` | BOOLEAN | Visible par les membres |
| `link_url` | TEXT | Lien (optionnel) |
| `image_url` | TEXT | Image (optionnel) |
| `file_url` | TEXT | Fichier (optionnel) |
| `file_name` | TEXT | Nom du fichier |
| `timestamp` | TIMESTAMPTZ | |
| `created_at` | TIMESTAMPTZ | |

**RLS** : INSERT authentifié, SELECT/UPDATE/DELETE admin.

---

#### `public.push_subscriptions`

| Colonne | Type | Description |
|---|---|---|
| `id` | UUID (PK) | |
| `user_id` | UUID (FK users) | |
| `endpoint` | TEXT (UNIQUE) | Endpoint push |
| `p256dh` | TEXT | Clé publique VAPID |
| `auth` | TEXT | Secret d'authentification |
| `user_agent` | TEXT | Navigateur |
| `created_at` | TIMESTAMPTZ | |

**RLS** : SELECT/INSERT/DELETE par l'utilisateur propriétaire uniquement.

---

### 7.2 Stockage (Supabase Storage)

| Bucket | Visibilité | Usage |
|---|---|---|
| `messages_attachments` | Privé | Pièces jointes des messages |
| `events` | Public | Images et fichiers des événements |

---

## 8. Notifications et temps réel

### 8.1 Notifications push (Web Push / VAPID)

L'application utilise le standard Web Push avec des clés VAPID pour envoyer des notifications aux navigateurs des membres, même lorsque l'application n'est pas ouverte.

**Composants :**

| Fichier | Rôle |
|---|---|
| `web/push_sw.js` | Service Worker : reçoit et affiche les notifications push |
| `web/push_utils.js` | Pont JS↔Flutter : subscribe / unsubscribe |
| `lib/services/notification_service.dart` | Côté Flutter : gestion des abonnements |
| `supabase/functions/send-push/index.ts` | Edge Function : envoi des notifications |

**Déclencheurs automatiques (webhooks Supabase) :**

| Événement | Destinataires | Message |
|---|---|---|
| Nouvelle inscription membre | Tous les admins | "Nouvelle demande d'adhésion de {nom}" |
| Compte approuvé / refusé | L'utilisateur concerné | "Compte approuvé" ou "Demande refusée" |
| Nouvel événement créé | Tous les adhérents | "Nouvel événement : {thème}" |

**Flow d'abonnement :**
1. Après approbation du compte, l'app demande la permission de notification
2. Le Service Worker est enregistré (`/push-sw-scope/`)
3. L'abonnement (endpoint + clés) est stocké dans `push_subscriptions`
4. L'Edge Function `send-push` interroge cette table pour cibler les destinataires

### 8.2 Temps réel (Supabase Realtime)

- **Annuaire** : mise à jour instantanée des profils via WebSocket Supabase
- **Blocage** : détection immédiate si un admin bloque un compte connecté (déconnexion forcée)
- Tables configurées avec REPLICA IDENTITY FULL pour les événements Realtime

---

## 9. Sécurité et conformité

### 9.1 Authentification et autorisation

- Authentification par email/mot de passe via Supabase Auth (JWT)
- Toutes les requêtes sont authentifiées via le token JWT
- **Row Level Security (RLS)** activé sur toutes les tables PostgreSQL
- Chaque politique RLS vérifie l'identité (`auth.uid()`) et le rôle
- La clé `service_role` (admin DB) n'est utilisée que dans les Edge Functions côté serveur

### 9.2 Politiques RLS

Exemples de politiques appliquées :

| Table | Opération | Condition |
|---|---|---|
| `users` | SELECT | Authentifié |
| `users` | UPDATE | Propriétaire OU admin |
| `events` | SELECT | Authentifié |
| `events` | INSERT/UPDATE/DELETE | Admin uniquement |
| `registrations` | INSERT/DELETE | Propriétaire OU admin |
| `feedbacks` | INSERT | Propriétaire OU admin |
| `messages` | INSERT | Authentifié |
| `messages` | SELECT/UPDATE/DELETE | Admin uniquement |
| `push_subscriptions` | ALL | Propriétaire uniquement |
| `cgu_acceptances` | ALL | Propriétaire uniquement |

### 9.3 Conformité et données personnelles

- **CGU** versionnées et acceptées explicitement par chaque membre
- Les données professionnelles ne sont partagées dans l'annuaire que si `share_pro_info = true`
- Données hébergées sur VPS privé en Europe (souveraineté des données)
- Pas d'analytique tiers ou de tracking publicitaire

---

## 10. Infrastructure et déploiement

### 10.1 Serveur

| Élément | Valeur |
|---|---|
| Hébergement | VPS dédié |
| IP | `46.225.133.77` |
| OS | Linux |
| Orchestration | Docker Compose |
| HTTPS | Let's Encrypt (cert auto-renouvelé) |
| URL production | `https://app.coentrepreneurs.fr` |
| Supabase Studio | `http://46.225.133.77:8080` (accès restreint) |

### 10.2 Services Docker

- **PostgreSQL** — base de données principale
- **Supabase API (PostgREST)** — API REST auto-générée
- **Supabase Auth** — service d'authentification
- **Supabase Realtime** — WebSocket temps réel
- **Supabase Storage** — stockage de fichiers
- **Supabase Edge Runtime** — exécution des Edge Functions
- **Kong** — API Gateway
- **InBucket** — serveur mail local (à remplacer par SMTP réel en production)

### 10.3 Edge Functions déployées

| Fonction | Déclencheur | Rôle |
|---|---|---|
| `send-push` | Appel direct | Envoi push VAPID ciblé |
| `webhook-user-signup` | INSERT sur `users` | Notification admin |
| `webhook-user-approved` | UPDATE sur `users` | Notification membre |
| `webhook-event-created` | INSERT sur `events` | Notification adhérents |

### 10.4 Stockage / Migrations

Migrations SQL versionnées dans `supabase/migrations/` :

| Fichier | Contenu |
|---|---|
| `001_initial_schema.sql` | Schéma complet (8 tables, RLS, triggers) |
| `002_push_subscriptions.sql` | Table `push_subscriptions` |
| `003_realtime_users.sql` | Activation Realtime sur `users` |
| `004_member_since_passions.sql` | Colonnes `member_since` et `passions` |

---

## 11. Contraintes et choix techniques

### 11.1 Contraintes

- Application exclusivement en **français**
- Interface utilisable sur **navigateur web** (desktop et mobile)
- Compatible avec les navigateurs supportant les **Service Workers** et l'**API Push**
- Données hébergées sur infrastructure privée (pas de cloud public imposé)
- Budget limité → pas de services tiers payants pour les notifications (VAPID gratuit)

### 11.2 Choix techniques justifiés

| Choix | Justification |
|---|---|
| Flutter Web | Une seule base de code pour web, mobile, desktop |
| Supabase self-hosted | Souveraineté des données, coût maîtrisé, BaaS complet |
| GoRouter v17 | Navigation déclarative avec redirections conditionnelles testables |
| Provider (AuthService) | Simplicité : un seul état global nécessaire |
| VAPID / Web Push | Standard W3C, sans Firebase, sans abonnement tiers |
| Deno / Edge Functions | Serverless léger, TypeScript, déployé au plus près de la DB |
| Material 3 | Design system moderne, thème personnalisable |
| Google Fonts Inter | Typographie lisible et professionnelle |
| RLS PostgreSQL | Sécurité au niveau données, indépendante de l'application |

### 11.3 Points d'amélioration identifiés (hors périmètre actuel)

- Remplacement d'InBucket par un vrai serveur SMTP (Brevo ou similaire) pour les emails transactionnels
- Mise en place de sauvegardes automatiques de la base de données
- Pipeline CI/CD (déploiement automatisé)
- Notifications push sur mobile natif (si app mobile Flutter publiée)

---

*Document rédigé le 09 mars 2026 — Coentrepreneurs*
