```markdown
# Résumé de `messages_page.dart`

**But :** Interface d'administration pour consulter et modérer les messages de contact
envoyés par les utilisateurs depuis la page d'accueil. Accessible uniquement aux admins
via le bouton "Consulter les messages" de `home_page`.

---

## Architecture générale

```
MessagesPage (StatefulWidget)
├── StreamBuilder → messages (Realtime, tri décroissant)
│   └── ListView
│       └── Card + ExpansionTile (par message)
│           ├── En-tête : auteur, date, badge "Nouveau"
│           └── Détails dépliables
│               ├── _InfoRow email + rôle
│               ├── Catégorie + Message (texte)
│               ├── Lien cliquable (optionnel)
│               ├── Photo → FutureBuilder(_getSignedUrl) + FullscreenImageViewer
│               ├── Fichier → FutureBuilder(_getSignedUrl) + InkWell
│               └── Boutons d'action (lu / publier / supprimer)

_InfoRow (StatelessWidget)  — label + valeur en ligne
```

---

## État local

| Variable | Type | Rôle |
|---|---|---|
| `_currentAdminId` | `String?` | UID de l'admin connecté, utilisé pour `read_by` |

---

## Stream Supabase

Écoute la table `messages` entière via `.stream(primaryKey: ['id'])`.
Les messages sont triés **côté Dart** par `created_at` décroissant (plus récent en premier)
via un `.map()` sur le stream.

---

## Affichage d'un message

Chaque message est une `Card` avec `ExpansionTile`. La tuile est fermée par défaut,
affichant uniquement l'auteur, la date et le badge "Nouveau".

### En-tête (toujours visible)

| Élément | Détail |
|---|---|
| Nom | `user_name` en gras |
| Date | `created_at` formaté `dd/MM/yyyy HH:mm` via `intl` |
| Badge "Nouveau" | Affiché si `!_isReadByMe(data)` |

### `_isReadByMe(data)`

Vérifie si `_currentAdminId` est présent dans le tableau `read_by` du message.
Le champ `read_by` est un tableau de UIDs — permet un suivi de lecture par admin.

### Détails (dépliables)

| Section | Condition |
|---|---|
| Email + Rôle | Toujours (via `_InfoRow`) |
| Catégorie | Toujours |
| Message texte | Toujours |
| Lien cliquable | Si `link_url != null` |
| Photo | Si `image_url != null` → URL signée via `_getSignedUrl` |
| Fichier | Si `file_url != null` → URL signée via `_getSignedUrl` |
| Boutons d'action | Toujours |

---

## Pièces jointes — URLs signées

### `_getSignedUrl(stored)`

Les fichiers sont stockés dans le bucket **privé** `messages_attachments`.
Les URLs publiques stockées en base ne sont plus valides pour un bucket privé.

La méthode extrait le chemin relatif depuis l'URL stockée :
1. Cherche le marqueur `/messages_attachments/` dans l'URL
2. Si trouvé : extrait le chemin après le marqueur
3. Si l'URL ne commence pas par `http` : utilise la valeur telle quelle comme chemin
4. Sinon : retourne l'URL brute (cas non géré)

Appelle ensuite `storage.from('messages_attachments').createSignedUrl(path, 3600)`
pour générer une URL signée valide **1 heure**.

> Les `FutureBuilder` sur `_getSignedUrl` affichent un `CircularProgressIndicator`
> pendant la génération de l'URL, puis le widget final (image ou bouton fichier).

### Affichage image

`FullscreenImageViewer` (widget externe) avec `thumbnailHeight: 200`.
Permet d'ouvrir l'image en plein écran au tap.

### Affichage fichier

`InkWell` orange avec nom de fichier (`file_name`) et icône de téléchargement.
Tap → `_launchUrl(signedUrl)` pour ouvrir dans le navigateur externe.

---

## Actions admin

### Boutons d'action — logique d'affichage

Les boutons sont mutuellement exclusifs et s'affichent selon l'état du message :

| État | Bouton gauche | Bouton droit |
|---|---|---|
| Non lu | ✅ "Marquer comme lu" (vert) | 🗑 "Supprimer" (rouge) |
| Lu, non publié | 📢 "Publier" (bleu) | 🗑 "Supprimer" (rouge) |
| Publié | Badge "✓ Publié" (lecture seule) | 🗑 "Supprimer" (rouge) |

### `_markAsRead(id)`

1. Récupère le tableau `read_by` actuel du message
2. Ajoute `_currentAdminId` si absent
3. Met à jour `messages.read_by` avec le nouveau tableau

### `_publishMessage(id)`

1. Met à jour `messages.published = true`
2. Ajoute l'`id` du message dans `users.read_notification_message_ids` de l'admin
   qui publie (évite que le badge de notification se déclenche pour lui-même)

### `_deleteMessage(id)`

Affiche un `AlertDialog` de confirmation (action irréversible).
En cas de confirmation : `DELETE` sur `messages` avec filtre `id`.

### `_launchUrl(url)`

Schémas autorisés : `http`, `https`, `tel`, `mailto`.
Ouvre via `LaunchMode.externalApplication`.

---

## Widget utilitaire : `_InfoRow`

Affiche une ligne `label : valeur` avec le label en gras (`labelSmall`) et
la valeur en `bodySmall`. Utilisé pour email et rôle.

---

## Tables et buckets Supabase

| Ressource | Opérations | Champs concernés |
|---|---|---|
| `messages` (table) | SELECT (stream), UPDATE, DELETE | `user_name`, `user_email`, `user_role`, `category`, `message`, `created_at`, `read_by`, `published`, `link_url`, `image_url`, `file_url`, `file_name` |
| `users` (table) | SELECT + UPDATE | `read_notification_message_ids` |
| `messages_attachments` (bucket) | `createSignedUrl` (lecture) | Chemin relatif extrait de `image_url` / `file_url` |

## Packages et widgets externes

| Élément | Rôle |
|---|---|
| `intl` | Formatage de date `DateFormat('dd/MM/yyyy HH:mm')` |
| `url_launcher` | Ouverture liens et fichiers |
| `FullscreenImageViewer` | Affichage image avec zoom plein écran |
```