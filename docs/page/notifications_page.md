```markdown
# Résumé de `notifications_page.dart`

**But :** Centre de notifications unifié avec 3 onglets. L'affichage et les actions
s'adaptent selon le rôle de l'utilisateur connecté (admin vs adhérent/invité).
Le retour vers `home_page` déclenche un rafraîchissement du badge de notifications.

---

## Architecture générale

```
NotificationsPage (StatefulWidget)
├── Onglets manuels (GestureDetector + border bottom)
│   ├── Onglet 0 — Adhésions    (badge : Future cache)
│   ├── Onglet 1 — Rencontres   (badge : StreamBuilder<events>)
│   └── Onglet 2 — Messages     (badge : StreamBuilder<messages>)
└── Corps
    ├── _buildAdherentsTab()
    │   ├── [admin]   _buildPendingApprovalsView()
    │   └── [autres]  _buildNewMembersView()
    ├── _buildEventsTab()        — StreamBuilder<events>
    └── _buildMessagesTab()      — StreamBuilder<messages>
        └── _buildMessageCard()  — carte message avec pièces jointes
```

---

## État local

| Variable | Type | Rôle |
|---|---|---|
| `_selectedTab` | `int` | Onglet actif (0/1/2) |
| `_readEventIds` | `Set<String>` | IDs d'événements marqués lus (cache local) |
| `_readMessageIds` | `Set<String>` | IDs de messages marqués lus (cache local) |
| `_readNewMemberIds` | `Set<String>` | IDs de membres vus (cache local) |
| `_isAdmin` | `bool` | Rôle de l'utilisateur connecté |
| `_currentUserId` | `String?` | UID courant |
| `_pendingUsers` | `List<Map>` | Demandes en attente (chargées via Future) |
| `_approvedMembers` | `List<Map>` | Nouveaux membres approuvés (7 derniers jours) |
| `_loadingUsers` | `bool` | Indicateur de chargement de la liste utilisateurs |
| `_messageSearchController` | `TextEditingController` | Recherche dans l'onglet Messages |
| `_messageSearchQuery` | `String` | Requête courante (sync via listener) |
| `_messageSortOrder` | `String` | Tri actif : `'date'` / `'category'` / `'alpha'` |
| `_showReadMessages` | `bool` | Toggle affichage des messages déjà lus |

> Les Sets `_read*Ids` servent de cache local : la mise à jour est immédiate côté UI,
> la persistance en base est effectuée en arrière-plan.

---

## Initialisation (`initState`)

Quatre opérations lancées en parallèle :
1. `_loadReadIds()` — charge les IDs lus depuis `users`
2. `_loadUserInfo()` — détermine le rôle et l'UID
3. `_loadUsers()` — charge `_pendingUsers` + `_approvedMembers` via `Future.wait`
4. Listener sur `_messageSearchController` pour mettre à jour `_messageSearchQuery`

---

## Stratégie de données par source

| Source | Mécanisme | Raison |
|---|---|---|
| `users` (pending/approved) | `Future` rechargeable (`_loadUsers`) | Rechargement immédiat garanti après approbation/rejet |
| `events` | Stream Realtime (`_getNewEvents`) | Mises à jour automatiques sans action admin |
| `messages` | Stream Realtime (`_getPublishedMessages`) | Mises à jour automatiques à la publication |
| IDs lus | Future one-shot (`_loadReadIds`) + cache local Set | Cohérence immédiate sans attendre la base |

---

## Onglet Adhésions

### Vue admin — `_buildPendingApprovalsView`

Liste des utilisateurs avec `approval_status == 'pending'`, chargée via `_fetchPendingUsers`.
Chaque carte affiche : avatar, nom, email, téléphone, date de demande + boutons.

#### `_approveUser(uid, prenom, nom)`
Met à jour dans `users` : `approval_status → 'approved'`, `approved_at → now()`, `role → 'adherent'`.
Appelle `_loadUsers()` après pour rafraîchir la liste.

#### `_rejectUser(uid, prenom, nom)`
Affiche un `AlertDialog` de confirmation, puis met à jour : `approval_status → 'rejected'`, `blocked → true`.
Appelle `_loadUsers()` après.

### Vue utilisateur — `_buildNewMembersView`

Liste des membres approuvés dans les 7 derniers jours (hors utilisateur courant).
Chargée via `_fetchApprovedMembers` avec filtre `approved_at >= now - 7j`.

Les membres non vus apparaissent en premier (nom en gras), les vus en dessous (nom normal + icône ✓).

#### `_markNewMemberAsSeen(memberId)`
Ajoute l'ID au Set local `_readNewMemberIds` immédiatement, puis persiste dans
`users.read_new_member_ids` en arrière-plan.

---

## Onglet Rencontres — `_buildEventsTab`

### `_getNewEvents()`

Stream Realtime sur `events`. Filtre côté Dart :
- `created_at` ≥ aujourd'hui (créé aujourd'hui ou plus récemment)
- `date` (jour de la rencontre) ≥ aujourd'hui (pas encore passé)

Résultat trié par `createdAt` décroissant. Non lus en premier dans la liste.

#### `_markAsRead(eventId)`
Ajoute au Set local `_readEventIds`, puis persiste dans `users.read_notification_event_ids`.

---

## Onglet Messages — `_buildMessagesTab`

### `_getPublishedMessages()`

Stream Realtime sur `messages`, filtré sur `published == true` côté Dart.
Normalise les noms de champs (double clé `camelCase`/`snake_case` pour compatibilité
avec les anciennes données stockées).
Tri par `timestamp` décroissant.

### `_isMessageRead(msg)`

Un message est considéré lu si :
- Son ID est dans `_readMessageIds`, **ou**
- Il a été envoyé par l'utilisateur courant (`user_id == _currentUserId`)

### `_applyMessageFiltersAndSort(messages)`

Applique sur une liste :
1. Filtre texte sur `message`, `userName`, `category`
2. Tri selon `_messageSortOrder` :
   - `'date'` : par `timestamp` décroissant
   - `'category'` : alphabétique sur `category`
   - `'alpha'` : alphabétique sur `message`

### Interface de l'onglet Messages

| Élément | Détail |
|---|---|
| Barre de recherche | `TextField` avec bouton ✕ si requête non vide |
| `SegmentedButton` | 3 options de tri : Date / Catégorie / A-Z |
| Messages non lus | Toujours visibles, filtrés + triés |
| Messages lus | Masqués par défaut, toggle via `_showReadMessages` |

#### `_markMessageAsRead(messageId)`
Ajoute au Set local `_readMessageIds`, puis persiste dans `users.read_notification_message_ids`.

### `_buildMessageCard(msg, isDark)`

Carte commune pour les messages publiés. Affiche :
- Avatar orange (icône `campaign` si non lu, `mark_email_read` si lu)
- Nom de l'auteur (gras si non lu) + catégorie
- Corps du message
- Lien cliquable (si `linkUrl` non null)
- Image via `_getSignedUrl` + `FullscreenImageViewer` (si `imageUrl` non null)
- Fichier via `_getSignedUrl` + `InkWell` (si `fileUrl` non null)
- Date + bouton "Marquer comme vu" (si non lu)

---

## Gestion des URLs signées

### `_getSignedUrl(stored)`

Identique à `messages_page.dart` : extrait le chemin relatif depuis l'URL stockée
en cherchant le marqueur `/messages_attachments/`, puis génère une URL signée
valide 1 heure via `storage.createSignedUrl`.

---

## Badges de comptage dans les onglets

| Onglet | Source du badge |
|---|---|
| Adhésions (admin) | `_pendingUsers.length` (cache local) |
| Adhésions (autres) | `_approvedMembers.where(!_readNewMemberIds.contains).length` |
| Rencontres | `StreamBuilder<events>` → filtre `!_readEventIds.contains` |
| Messages | `StreamBuilder<messages>` → filtre `!_isMessageRead` |

---

## Tables Supabase

| Table | Opérations | Champs concernés |
|---|---|---|
| `users` | SELECT (Future), UPDATE | `approval_status`, `approved_at`, `role`, `blocked`, `read_notification_event_ids`, `read_notification_message_ids`, `read_new_member_ids` |
| `events` | SELECT (stream Realtime) | `id`, `theme`, `date`, `lieu`, `created_at` |
| `messages` | SELECT (stream Realtime) | `id`, `user_id`, `user_name`, `category`, `message`, `published`, `timestamp`, `link_url`, `image_url`, `file_url`, `file_name` |
| `messages_attachments` (bucket) | `createSignedUrl` | Chemin relatif extrait de `image_url` / `file_url` |

## Packages et widgets externes

| Élément | Rôle |
|---|---|
| `intl` | Formatage dates `DateFormat` |
| `url_launcher` | Ouverture liens et fichiers |
| `FullscreenImageViewer` | Affichage image zoomable plein écran |
```