# Résumé de `home_page.dart`

**But :** Page d'accueil principale de l'application. Orchestre le contrôle d'accès
(CGU, approbation, blocage), les notifications, les événements à venir et la navigation
vers toutes les sections de l'app. Point d'entrée unique après connexion.

---

## Architecture générale

HomePage (StatefulWidget)
├── AppBar
│   ├── Badge notifications (StreamBuilder<int>)
│   ├── Bouton calendrier (StreamBuilder<User?>)
│   ├── Bouton FAQ
│   ├── Bouton paramètres
│   └── Toggle thème + Déconnexion
└── Body — StreamBuilder<User?> (authStateChanges)
├── [admin]     → _buildMainContent()
├── [!CGU]      → _buildAccessDeniedScreen()
├── [pending]   → _buildPendingApprovalScreen()
├── [rejected]  → _buildRejectedScreen()
└── [approved]  → _buildMainContent()
├── _buildWelcomeSection()
├── _buildContactSection()     — 5 boutons de messagerie
├── _buildEventsSection()      — événements à venir + FeedbackPrompt
└── _buildActionsSection()     — boutons admin + annuaire
_MessageFormDialog (StatefulWidget)  — formulaire de message avec pièces jointes
_ContactButton (StatelessWidget)     — bouton réutilisable dans la section contact

---

## État local et streams cachés

| Variable | Type | Rôle |
|---|---|---|
| `_cguCheckCompleted` | `bool` | Indique si la vérification asynchrone des CGU est terminée |
| `_userAcceptedCGU` | `bool` | Résultat de la vérification CGU |
| `_authStream` | `Stream<User?>?` | Stream d'authentification mis en cache (initialisé une seule fois dans `initState`) |
| `_eventsStream` | `Stream<List<Event>>?` | Stream événements mis en cache |
| `_approvalStream` | `Stream<Map?>?` | Stream de polling du statut d'approbation |
| `_cachedApprovalUid` | `String?` | UID utilisé pour le stream d'approbation (évite de recréer si inchangé) |
| `_notificationCountStream` | `Stream<int>?` | Stream de polling du compteur de notifications |
| `_blockedChannel` | `RealtimeChannel?` | Channel Realtime pour détecter un blocage admin |
| `_listenedUid` | `String?` | UID écouté par le channel (évite un double abonnement) |

> Les streams sont mis en cache comme champs (`??=`) pour ne pas être recréés
> à chaque `build`. Le recalcul est déclenché explicitement via `_refreshNotificationCount()`
> ou en modifiant `_cachedApprovalUid`.

---

## Contrôle d'accès — flux complet

User connecté ?
└── Admin → accès immédiat (_buildMainContent)
└── Non-admin
└── CGU vérifiées ? (_cguCheckCompleted)
└── Non → spinner
└── Oui
└── CGU acceptées ?
└── Non → _buildAccessDeniedScreen
└── Oui → polling approval_status
└── 'rejected'  → _buildRejectedScreen
└── 'approved'  → _buildMainContent
└── autre/null  → _buildPendingApprovalScreen

La sécurité par défaut est inversée : tout statut inconnu ou absent bloque l'accès.

---

## Vérification et gestion des CGU

### `_checkAndHandleCGU()`

Appelée depuis `initState`. Récupère l'utilisateur courant via `AuthService`,
vérifie via `CGUService.hasUserAcceptedCGU()` si les CGU ont été acceptées,
puis déclenche `_showCGUDialog()` si nécessaire.

> Opération asynchrone lancée depuis `initState` — vérifie `mounted` avant `setState`.

### `_showCGUDialog(userId)`

Affiche `CGUAcceptanceDialog` avec `barrierDismissible: false`.

En cas d'acceptation :
1. Appelle `CGUService.acceptCGU(userId)`
2. Vérifie le `approval_status` courant avant de le passer à `'pending'`
   (évite d'écraser `'approved'` en cas de problème réseau sur le check CGU)
3. Affiche un SnackBar orange informant que la demande est en attente

En cas de refus (`.then` sur `showDialog`) : appelle `_handleCGURejection()`
qui force la déconnexion via un dialog non fermable.

---

## Listener de blocage temps réel

### `_startBlockedListener(uid)`

Crée un `RealtimeChannel` Supabase sur les UPDATE de `users` filtrés sur `id == uid`.
Si `blocked == true` est reçu dans le payload :
1. Affiche un SnackBar rouge d'avertissement
2. Attend 1 seconde puis appelle `_logout()`

Le channel est désabonné dans `dispose()`. Un garde sur `_listenedUid` évite
un double abonnement si `build` est appelé plusieurs fois avec le même utilisateur.

---

## Streams de polling

### `_getUserApprovalStream(uid)` — toutes les 10 secondes

Crée un `StreamController.broadcast()` et un `Timer.periodic` qui interroge
`users.approval_status` toutes les 10 secondes. Ferme et recrée le controller
si l'UID change. Émet `null` en cas d'erreur réseau.

### `_getTotalNotificationsCount()` — toutes les 30 secondes

Même pattern que ci-dessus, mais appelle `_computeNotificationCount()`.

### `_computeNotificationCount()`

Calcule le total de 3 compteurs :

| Compteur | Admin | Utilisateur |
|---|---|---|
| Adhésions | Demandes `pending` en attente | Nouveaux membres approuvés dans les 7 derniers jours, non vus (`read_new_member_ids`) |
| Événements | — | Événements créés aujourd'hui ou plus récents, dont la date n'est pas passée, non vus (`read_notification_event_ids`) |
| Messages | — | Messages publiés (`published == true`) non vus (`read_notification_message_ids`) |

### `_refreshNotificationCount()`

Ferme les streams et controllers de notifications et force un `setState` pour
déclencher la recréation du stream via `??=` au prochain build.
Appelé au retour de `NotificationsPage` (`.then` sur `Navigator.push`).

---

## Initialisation des push notifications

### `_initPushNotifications()`

Exécuté uniquement sur le web (`kIsWeb`). Vérifie que l'utilisateur courant
a le statut `'approved'` avant d'appeler `NotificationService.initialize(uid)`.
Évite d'enregistrer un token push pour un compte en attente ou bloqué.

---

## Sections de l'écran principal (`_buildMainContent`)

### `_buildWelcomeSection`

Ligne "Bienvenue, {prénom}" + badge rôle violet en haut de page.

### `_buildContactSection`

Container avec dégradé bleu/violet contenant 5 boutons `_ContactButton` verts,
chacun ouvrant `_MessageFormDialog` avec une catégorie prédéfinie :

| Bouton | Catégorie |
|---|---|
| Une idée | `'Nouvelle idée'` |
| Besoin d'aide | `'Demande d\'aide'` |
| Un problème | `'Signalement de problème'` |
| Bon plan | `'Bon plan à proposer'` |
| Merci qui ? | `'Merci qui'` |

### `_buildEventsSection`

`StreamBuilder` sur `_eventsStream` (mis en cache). Filtre les événements dont
la date est aujourd'hui ou future, puis limite à 5 via `.take(5)`.

Affiche aussi des `FeedbackPrompt` invisibles pour chaque événement terminé —
widgets externes qui déclenchent le formulaire de feedback au bon moment.

Un tap sur une `EventCard` affiche un `MaterialBanner` qui se ferme automatiquement
après 4 secondes.

### `_buildActionsSection`

Boutons de navigation visibles uniquement pour les admins :
- **Gérer les événements** → `AdminEventsPage` (violet)
- **Consulter les messages** → `MessagesPage` (orange)
- **Gérer les utilisateurs** → `AdminUsersPage` (indigo)

Bouton visible pour tous :
- **Consulter les adhérents** → `DirectoryPageDynamic` (vert foncé)

---

## `_MessageFormDialog`

Formulaire plein écran pour envoyer un message à l'administration.

### Champs

| Champ | Obligatoire |
|---|---|
| Message texte libre | ✅ |
| Lien URL | ❌ |
| Photo (galerie, qualité 80 %) | ❌ |
| Fichier joint (tout type) | ❌ |

### `_submitMessage()`

1. Valide que le message n'est pas vide
2. Upload image si présente → bucket `messages_attachments`
3. Upload fichier si présent → bucket `messages_attachments`
4. Insert dans `messages` avec : `user_id`, `user_name`, `user_email`, `user_role`,
   `category`, `message`, `created_at`, `read: false`, `read_by: [uid]`,
   et les champs optionnels non nuls

---

## Tables et buckets Supabase

| Ressource | Opérations | Champs concernés |
|---|---|---|
| `users` (table) | SELECT, UPDATE, Realtime | `approval_status`, `blocked`, `role`, `read_notification_event_ids`, `read_notification_message_ids`, `read_new_member_ids`, `approved_at` |
| `events` (table) | SELECT (stream + polling) | `id`, `created_at`, `date` |
| `messages` (table) | SELECT, INSERT | `id`, `published`, `user_id`, `category`, `message`, etc. |
| `messages_attachments` (bucket) | uploadBinary | `{uid}/{ts}_image.ext`, `{uid}/{ts}_filename` |

## Services et widgets externes

| Élément | Rôle |
|---|---|
| `AuthService` | Stream d'auth + utilisateur courant + logout |
| `CGUService` | Vérification et enregistrement d'acceptation des CGU |
| `EventService` | Stream Realtime des événements + init événements par défaut |
| `NotificationService` | Init push web + suppression de subscription |
| `ThemeNotifier` | Toggle thème clair/sombre (`Consumer<ThemeNotifier>`) |
| `CGUAcceptanceDialog` | Dialog de lecture et acceptation des CGU |
| `EventCard` | Carte événement avec inscription |
| `FeedbackPrompt` | Widget invisible déclencheur de formulaire de feedback |
| `NotificationsPage` | Page de notifications (retour → refresh badge) |