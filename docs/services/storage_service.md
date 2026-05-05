# Résumé de `storage_service.dart`

**But :** Service utilitaire d'upload de fichiers vers Supabase Storage.
Fournit une interface simple en un seul appel pour uploader et obtenir
l'URL publique d'un fichier. Utilisé par `AdminEventsPage` (_EventFormDialog)
et `SettingsPage` pour les photos de profil et pièces jointes.

---

## `uploadFile(...)`

| Paramètre | Type | Obligatoire | Rôle |
|---|---|---|---|
| `bucket` | `String` | ✅ | Nom du bucket Supabase (ex. `'avatars'`, `'events'`) |
| `path` | `String` | ✅ | Chemin relatif dans le bucket (ex. `'events_attachments/123.jpg'`) |
| `bytes` | `Uint8List` | ✅ | Contenu binaire du fichier |
| `contentType` | `String?` | ❌ | Type MIME (ex. `'image/jpeg'`, `'application/octet-stream'`) |

Flux d'exécution :
1. Obtient la référence au bucket via `_supabase.storage.from(bucket)`
2. Upload via `uploadBinary` avec `upsert: true` — écrase silencieusement
   un fichier existant au même chemin
3. Retourne l'URL publique via `getPublicUrl(path)`

> `upsert: true` permet de remplacer une photo de profil ou une pièce jointe
> existante sans supprimer l'ancienne entrée au préalable.
> L'URL retournée est **publique** — convient pour `avatars` et `events`,
> mais pas pour `messages_attachments` (bucket privé géré via URLs signées
> dans `MessagesPage` et `NotificationsPage`).

---

## Buckets utilisés dans l'application

| Bucket | Visibilité | Contenu |
|---|---|---|
| `avatars` | Public | Photos de profil (`SettingsPage`) |
| `events` | Public | Images et fichiers joints aux événements (`AdminEventsPage`) |
| `messages_attachments` | Privé | Pièces jointes des messages (non géré par ce service) |

---

## Points d'attention

- Le service ne gère pas la suppression des anciens fichiers lors d'un
  remplacement — les fichiers orphelins s'accumulent dans le bucket.
- Aucune validation du type ou de la taille du fichier n'est effectuée
  côté service — la validation est à la charge de l'appelant.
- `getPublicUrl` génère une URL sans expiration — ne pas utiliser pour
  des buckets privés.