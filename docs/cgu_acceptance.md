Résumé de `cgu_acceptance.dart`

But: Modèle pour représenter l'acceptation des CGU par utilisateur.

Points clés

- Champs : `userId`, `hasAccepted`, `acceptedDate`, `cguVersion`.
- `toMap` / `fromMap` utilisent une chaîne ISO pour la date (`toIso8601String`).
- Contrainte unique Supabase sur `(user_id, cgu_version)` — empêche les
  doublons pour un même utilisateur et une même version de CGU.
- Le `CGUService` utilise une logique select → update/insert (et non upsert)
  pour contourner les limitations PostgREST/RLS avec cette contrainte.

Conseils

- Pour l'audit, vous pouvez stocker une collection d'historique au lieu d'écraser
  le document si vous avez besoin d'un trail des acceptations.
