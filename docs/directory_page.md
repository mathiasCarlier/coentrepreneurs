Résumé de `directory_page.dart`

But: Annuaire statique des membres — affichage de cartes et actions de contact (appel, mail, site).

Points clés

- `members` : liste statique de map; structure libre mais utilisée de façon cohérente.
- `_launchURL` : ouvre `tel:`, `mailto:` ou URL web avec `url_launcher`.
- Widgets utilitaires : `_buildCard`, `_buildContactInfo`, `_buildActionButtons`, `_buildButton`.

Conseils

- Si la liste grossit, déplacer `members` dans Firestore et paginer.
- Valider/normaliser les numéros de téléphone/URLs lors de l'import.
