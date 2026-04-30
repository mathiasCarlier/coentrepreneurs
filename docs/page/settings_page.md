Résumé de `settings_page.dart`

But: Page de paramètres utilisateur — profil, infos professionnelles, compte.

Points clés

- Profil personnel
  - `_saveUserInfo()` : sauvegarde prénom, nom, téléphone.
  - `_pickPhoto()` / `_uploadPhoto()` : upload avatar vers le bucket `avatars`.

- Informations professionnelles
  - `_saveProfessionalInfo()` : entreprise, compétences, adresse, site web.
  - `_toggleShareProInfo()` : active/désactive la visibilité dans l'annuaire
    (champ `share_pro_info`).

- Gestion du compte
  - `_showChangePasswordDialog()` : changement de mot de passe via Supabase Auth
    avec ré-authentification.
  - `_showCGUDialog()` : relecture et acceptation des CGU.

- Chargement des données
  - `_loadUserData()` : récupère les données depuis la table `users`.

Table Supabase: `users`
Bucket Storage: `avatars`
Champs gérés: `prenom`, `nom`, `phone`, `company_name`, `skills`,
`professional_address`, `website`, `share_pro_info`, `photo_url`
