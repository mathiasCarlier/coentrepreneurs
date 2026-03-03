Résumé de `storage_service.dart`

But: Abstraction pour l'upload de fichiers vers Supabase Storage.

Points clés

- Méthode unique: `uploadFile(bucket, path, bytes, contentType?)`
  - Upload binaire avec flag upsert (écrase si existe).
  - Retourne l'URL publique du fichier.

- Utilisé par
  - `settings_page.dart` : upload avatar (bucket `avatars`).
  - `admin_events_page.dart` : upload image/fichier événement.

Buckets Supabase: `avatars` (et potentiellement d'autres pour les événements).
