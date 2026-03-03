Résumé de `directory_page_dynamic.dart`

But: Annuaire dynamique des membres — affichage des adhérents qui partagent
leurs infos professionnelles.

Points clés

- Données chargées depuis la table `users` (filtre `share_pro_info == true`).
- `_launchURL` : ouvre `tel:`, `mailto:` ou URL web avec `url_launcher`.
- Affichage en cartes avec photo, nom, entreprise, compétences.
- Actions de contact : appel, email, site web.

Conseils

- Paginer si le nombre d'adhérents devient important.
- Valider/normaliser les numéros de téléphone/URLs lors de la saisie (settings_page).
