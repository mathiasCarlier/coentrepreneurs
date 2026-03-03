Résumé de `admin_users_page.dart`

But: Interface d'administration pour gérer les comptes utilisateurs.

Points clés

- Deux onglets : "Adhérents" et "Invités"
  - Chaque onglet affiche les utilisateurs filtrés par rôle.
  - Stream Realtime sur la table `users` avec filtre `role`.
  - Recherche locale par nom ou email.
  - Badge compteur dans chaque onglet.

- Changement de rôle
  - Méthode: `_changeRole(uid, newRole)`
  - Dialog avec radio buttons: adhérent ("Accès complet") ou invité ("Accès limité").
  - Met à jour le champ `role` dans la table `users`.

- Blocage / Déblocage
  - Méthode: `_toggleBlock(uid, isCurrentlyBlocked)`
  - Dialog de confirmation avec message explicite.
  - Met à jour le champ `blocked` (bool) dans la table `users`.
  - Un utilisateur bloqué ne peut plus se connecter (vérifié dans `AuthService.login`).

- Indicateurs visuels
  - Couleurs: bleu = adhérent, orange = invité, rouge = bloqué.
  - Icône cadenas pour les utilisateurs bloqués.

Table Supabase: `users`

Accès: réservé aux administrateurs (vérification côté UI dans home_page).
