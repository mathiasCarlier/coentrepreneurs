Résumé de `cgu_service.dart`

But: Service responsable de la vérification et de l'enregistrement de
l'acceptation des Conditions Générales d'Utilisation (CGU) par utilisateur.

Points clés et parties complexes

- Versioning des CGU
  - Constante: `currentCGUVersion` (ex: '1.0').
  - Si le texte des CGU change, incrémentez la version pour forcer les
    utilisateurs à ré-accepter.

- Stockage Firestore
  - Collection: `cgu_acceptances`
  - Document ID: `userId`
  - Champs attendus: `{ userId, hasAccepted: bool, acceptedDate: Timestamp, cguVersion: string }`
  - `hasUserAcceptedCGU(userId)` lit le document et vérifie `hasAccepted` et
    `cguVersion == currentCGUVersion`.

- Méthode `acceptCGU(userId)`
  - Écrit/écrase le document d'acceptation avec la `currentCGUVersion` et
    l'horodatage actuel.

Conseils

- Lors d'une mise à jour des CGU, pensez à informer l'utilisateur dans
  l'UI avant de requérir la nouvelle acceptation.
- Conserver un historique des versions (si besoin) peut aider pour l'audit.
