# Résumé de `admin_events_page.dart`

**But :** Interface complète de gestion des événements pour les administrateurs.
Accessible uniquement côté admin, elle couvre la consultation, la création, l'édition,
le suivi en temps réel et le bilan post-événement.

---

## Architecture générale

AdminEventsPage (StatefulWidget)
├── EventService (stream Realtime)
├── _SectionHeader             — en-tête de groupe (avec/sans compte-rendu)
├── _EventCard                 — carte compacte dans la liste
├── _EventDetailsSheet         — bottom sheet détaillée (StatefulWidget)
│   ├── _DetailSection         — ligne icône + label + valeur
│   ├── _ParticipantsSection   — inscrits / confirmés / déclinés (stream)
│   ├── EventGuestsSection     — section invités (widget externe)
│   └── _SummaryDialog         — éditeur markdown du compte-rendu
└── _EventFormDialog           — formulaire création / édition (StatefulWidget)

---

## Composants détaillés

### `AdminEventsPage`

Widget racine de la page. Il écoute un `StreamBuilder` sur
`EventService.getAllEventsStream()` (stream Supabase Realtime sur la table `events`).

Les événements sont ensuite séparés en deux groupes :
- **Sans compte-rendu** (`hasSummary == false`) — surlignés en orange
- **Avec compte-rendu** (`hasSummary == true`) — surlignés en vert

Chaque groupe est précédé d'un `_SectionHeader` et rendu via une liste de `_EventCard`.

Le FAB (FloatingActionButton) en bas à droite ouvre `_EventFormDialog` en mode création.

---

### `_SectionHeader`

Petite barre de titre avec un trait coloré vertical, le label du groupe et un badge
indiquant le nombre d'éléments. Paramètres : `label`, `count`, `color`.

---

### `_EventCard`

Carte compacte affichée dans la liste principale. Affiche :

| Élément | Détail |
|---|---|
| Thème | Titre de l'événement (2 lignes max) |
| Date | Badge bleu formaté `jj/mm/aaaa à HHhMM` |
| Statut | Badge coloré : 🟠 En attente / 🟣 En cours / ⚫ Terminé |
| Capacité | `currentParticipants / maxParticipants` + barre de progression |
| Complet | Badge rouge `⚠️ Complet` si `isFull == true` |
| Confirmés | Badge vert affiché uniquement si l'événement est `started` |

Un tap sur la carte ouvre `_EventDetailsSheet` via `showModalBottomSheet`.

---

### `_EventDetailsSheet`

Bottom sheet draggable (`DraggableScrollableSheet`) affichant toutes les informations
d'un événement. Taille initiale 70 %, jusqu'à 95 % de l'écran.

Contient un `StatefulWidget` interne (`_EventDetailsSheetState`) pour gérer :
- l'état local `_event` (mis à jour après chaque action sans recharger la sheet)
- le flag `_isToggling` (verrou pendant la transition de statut)

#### Sections affichées

| Section | Condition |
|---|---|
| Thème + date | Toujours |
| Badge statut | Toujours |
| Intervenant, Entreprise, Lieu | Toujours |
| Description | Si non nulle |
| Lien cliquable | Si non nul |
| Image cliquable | Si non nulle |
| Fichier téléchargeable | Si non nul |
| Capacité | Toujours |
| Confirmés | Si `isStarted` |
| `EventGuestsSection` | Si `isStarted` |
| `_ParticipantsSection` | Toujours |
| Section compte-rendu | Si `isFinished` |
| Bouton Démarrer / Terminer | Si `!isFinished` |
| Bouton Modifier | Si `!isFinished` |
| Bouton Supprimer | Toujours |

#### `_toggleEventStatus()`

Gère les transitions de statut via une dialog de confirmation :
- `pending` → `started` : ouvre les confirmations de présence
- `started` → `finished` : clôture l'événement

Appelle `EventService.updateEventStatus()` puis met à jour `_event` localement
via `setState` (sans attendre un rechargement depuis Supabase).

#### `_showSummaryDialog()`

Ouvre `_SummaryDialog` en dialog, récupère le texte saisi, appelle
`EventService.updateEventSummary()`, puis met à jour `_event.summary` localement.

---

### `_ParticipantsSection`

Liste les participants d'un événement. Utilise un `StreamBuilder` combiné :
- Premier chargement via `Stream.fromFuture(_fetchParticipants())`
- Rechargements automatiques via un stream Supabase sur la table `registrations`
  (filtrée sur `event_id`)

#### `_fetchParticipants()`

Effectue deux requêtes Supabase enchaînées :
1. `registrations` → récupère `user_id` + `status` pour l'événement
2. `users` → récupère `nom`, `prenom`, `email` via `.inFilter('id', userIds)`

Fusionne les deux résultats en une liste de maps `{ user_id, status, nom, prenom, email }`.

#### Affichage

Les participants sont répartis en deux groupes :
- **Inscrits** (statuts `registered` ou `confirmed`)
- **Ont décliné** (statut `declined`)

Chaque tuile `_buildUserTile` affiche un avatar avec initiales coloré selon le statut
(vert = confirmé, rouge = décliné, bleu = inscrit).

#### Boutons de pointage (si `isStarted && !isDeclined`)

| Cas | Bouton affiché |
|---|---|
| `registered` | ✅ **Confirmer** (vert) → passe à `confirmed` |
| `confirmed` | ❌ **Annuler** (rouge) → repasse à `registered` |

Ces actions appellent directement Supabase (`registrations.update`) sans passer par
un service dédié. Le stream se rafraîchit automatiquement après la mise à jour.

---

### `_SummaryDialog`

Dialog pleine largeur (400 px de hauteur) avec deux modes :
- **Édition** : `TextField` multilignes avec hint Markdown
- **Aperçu** : `MarkdownBody` (package `flutter_markdown_plus`)

Basculer entre les deux modes via le bouton `Éditer / Aperçu` dans le titre.
Valide et retourne le texte via `Navigator.of(context).pop(text)`.

---

### `_EventFormDialog`

Formulaire de création/édition affiché en plein écran (`fullscreenDialog: true`).

#### Champs obligatoires

| Champ | Contrôleur |
|---|---|
| Thème | `_themeController` |
| Intervenant | `_intervenantController` |
| Entreprise | `_entrepriseController` |
| Lieu | `_lieuController` |
| Max participants | `_maxParticipantsController` (entier ≥ 1) |
| Date | `_selectedDate` (DatePicker) |
| Heure | `_selectedTime` (TimePicker, optionnel) |

#### Champs optionnels

| Champ | Stockage |
|---|---|
| Description | `_descriptionController` |
| Lien URL | `_linkController` |
| Photo | `_imageBytes` + `_imageExtension` (ImagePicker) |
| Fichier joint | `_pickedFile` (FilePicker) |
| Collation / repas | `_hasCollation` (switch) + `_menuController` |

En mode édition, les URLs existantes sont pré-chargées dans `_existingImageUrl`,
`_existingFileUrl` et `_existingFileName`.

#### `_submitForm()`

Logique de soumission en plusieurs étapes :
1. Validation des champs obligatoires et de la collation
2. Upload image si `_imageBytes != null` → `StorageService.uploadFile()`
3. Upload fichier si `_pickedFile != null` → `StorageService.uploadFile()`
4. Construction de l'objet `Event`
5. Appel `EventService.createEvent()` ou `EventService.updateEvent()`
6. Nettoyage des champs supprimés (image, fichier, collation, description, lien)
   via un `update` direct sur Supabase avec les valeurs `null`

---

## Cycle de vie d'un événement

pending (En attente)
│  _toggleEventStatus()
▼
started (En cours)  ←── confirmations de présence ouvertes
│  _toggleEventStatus()
▼
finished (Terminé)  ←── compte-rendu Markdown disponible

Les transitions sont irréversibles : le bouton disparaît une fois l'état `finished`.

---

## Tables Supabase

| Table | Opérations |
|---|---|
| `events` | SELECT (stream), INSERT, UPDATE (statut, summary, champs nullables), DELETE |
| `registrations` | SELECT (stream par `event_id`), UPDATE (`status`) |
| `users` | SELECT (`.inFilter` sur les `user_id` des registrations) |

## Services utilisés

| Service | Rôle |
|---|---|
| `EventService` | CRUD événements + stream Realtime + updateStatus + updateSummary |
| `StorageService` | Upload image et fichier vers le bucket Supabase `events` |

## Packages Flutter impliqués

| Package | Usage |
|---|---|
| `supabase_flutter` | Client Supabase (stream, requêtes) |
| `image_picker` | Sélection photo depuis la galerie |
| `file_picker` | Sélection fichier quelconque |
| `url_launcher` | Ouverture liens et fichiers dans le navigateur externe |
| `flutter_markdown_plus` | Rendu Markdown dans le compte-rendu |
