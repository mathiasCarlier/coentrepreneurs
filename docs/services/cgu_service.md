Résumé de `cgu_service.dart`

But: Service responsable de la vérification et de l'enregistrement de
l'acceptation des Conditions Générales d'Utilisation (CGU) par utilisateur.

Points clés et parties complexes

- Versioning des CGU
  - Constante: `currentCGUVersion` (ex: '1.0').
  - Si le texte des CGU change, incrémentez la version pour forcer les
    utilisateurs à ré-accepter.

- Stockage Supabase
  - Table: `cgu_acceptances`
  - Contrainte unique: `(user_id, cgu_version)`
  - Champs: `user_id`, `has_accepted` (bool), `accepted_date` (ISO string), `cgu_version` (string)
  - `hasUserAcceptedCGU(userId)` lit l'enregistrement via `.maybeSingle()` et
    vérifie `hasAccepted` et `cguVersion == currentCGUVersion`.

- Méthode `acceptCGU(userId)`
  - Utilise une logique select → update ou insert (au lieu d'upsert) pour
    contourner les limitations de PostgREST avec les contraintes uniques
    composites et les politiques RLS.
  - Vérifie d'abord si un enregistrement existe pour ce couple (user_id, cgu_version).
  - Si oui: update `has_accepted` et `accepted_date`.
  - Si non: insert un nouvel enregistrement.

Conseils

- Lors d'une mise à jour des CGU, pensez à informer l'utilisateur dans
  l'UI avant de requérir la nouvelle acceptation.
- Conserver un historique des versions (si besoin) peut aider pour l'audit.
