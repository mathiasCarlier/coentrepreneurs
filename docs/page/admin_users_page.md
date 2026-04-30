# Résumé de `settings_page.dart`

**But :** Page de paramètres utilisateur permettant de consulter et modifier le profil
personnel, les informations professionnelles, la sécurité du compte et les CGU.
Reçoit un objet `user_model.User` en paramètre à la construction.

---

## Architecture générale

SettingsPage (StatefulWidget)
├── _buildProfileSection()          — avatar + nom + badge rôle
├── _buildUserInfoSection()         — infos personnelles (lecture / édition)
│   └── _buildParrainDropdown()     — sélection du parrain (DropdownButtonFormField)
├── _buildProfessionalInfoSection() — infos pro (lecture / édition + toggle annuaire)
├── BadgesSection                   — widget externe de gamification
├── _buildSecuritySection()         — changement de mot de passe + 2FA (à venir)
└── _buildLegalSection()            — consultation / acceptation des CGU

Chaque section est un `Container` avec fond grisé et bordure arrondie, affiché dans
un `SingleChildScrollView` vertical.

---

## État local

| Variable | Type | Rôle |
|---|---|---|
| `_user` | `user_model.User` | Copie locale de l'utilisateur, mise à jour après chaque sauvegarde |
| `_isEditing` | `bool` | Bascule mode lecture / édition des infos personnelles |
| `_isEditingPro` | `bool` | Bascule mode lecture / édition des infos professionnelles |
| `_isSaving` | `bool` | Verrou pendant une sauvegarde (désactive les boutons) |
| `_isUploadingPhoto` | `bool` | Verrou pendant l'upload de photo |
| `_selectedPhoto` | `XFile?` | Photo sélectionnée avant upload |
| `_memberSince` | `DateTime?` | Date de première adhésion (DatePicker) |
| `_selectedParrainId` | `String?` | UUID du parrain sélectionné |
| `_selectedParrainName` | `String?` | Nom résolu du parrain (pour affichage) |
| `_adherents` | `List<Map>` | Liste des adhérents/admins pour le dropdown parrain |

---

## Initialisation (`initState`)

1. Copie `widget.user` dans `_user`
2. Initialise tous les `TextEditingController` avec les valeurs courantes
3. Lance `_loadUserData()` pour rafraîchir depuis Supabase
4. Lance `_loadAdherents()` pour peupler le dropdown parrain

---

## Chargement des données

### `_loadUserData()`

Requête `SELECT *` sur `users` filtrée sur `_user.uid` (`.maybeSingle()`).
Met à jour `_user` **et** tous les contrôleurs texte en une seule passe `setState`.
Résout également le nom du parrain si `_adherents` est déjà chargé.

### `_loadAdherents()`

Requête `SELECT id, prenom, nom` sur `users`, filtrée sur les rôles `adherent` et `admin`,
excluant l'utilisateur courant (`.neq('id', _user.uid)`), triée par `nom`.
Après chargement, résout le nom du parrain si `_selectedParrainId` est déjà défini.

> Les deux chargements sont lancés en parallèle dans `initState` ; la résolution du
> nom du parrain est donc effectuée dans les deux méthodes pour gérer l'ordre d'arrivée.

---

## Section Profil (`_buildProfileSection`)

Affiche un `Container` avec dégradé bleu/violet (clair ou sombre selon le thème).

| Élément | Détail |
|---|---|
| Avatar 80×80 | Photo de profil (`photo_url`) ou initiales générées (prénom[0] + nom[0]) |
| Bouton caméra | Icône verte en bas à droite de l'avatar, déclenche `_pickPhoto()` |
| Spinner | Remplace l'icône caméra pendant `_isUploadingPhoto` |
| Nom complet | `prenom + nom` en `titleLarge` |
| Badge rôle | `_getRoleLabel(user.role)` sur fond vert |

### `_pickPhoto()`

Utilise `ImagePicker` avec source galerie, qualité 80 %, dimensions max 1024×1024.
Si une photo est sélectionnée, stocke dans `_selectedPhoto` et appelle immédiatement
`_uploadPhoto()`.

### `_uploadPhoto()`

1. Génère un nom de fichier unique : `{uid}_{timestamp}.jpg`
2. Lit les bytes via `_selectedPhoto!.readAsBytes()`
3. Upload dans le bucket Supabase `avatars` via `uploadBinary`
4. Récupère l'URL publique avec `getPublicUrl`
5. Met à jour `users.photo_url` dans Supabase
6. Met à jour `_user.photoUrl` localement et vide `_selectedPhoto`

---

## Section Informations personnelles (`_buildUserInfoSection`)

Deux modes contrôlés par `_isEditing` :

### Mode lecture

Affiche les champs non vides via `_InfoItem` :
prénom, nom, email, téléphone, date d'adhésion, passions, parrain, rôle.

### Mode édition

Affiche les `TextField` correspondants pour les champs modifiables + les champs
non modifiables (email, rôle) en lecture seule via `_InfoItem`.

| Champ | Contrôleur | Modifiable |
|---|---|---|
| Prénom | `_prenom` | ✅ |
| Nom | `_nom` | ✅ |
| Téléphone | `_phoneController` | ✅ |
| Date d'adhésion | `_memberSince` (DatePicker) | ✅ |
| Passions | `_passionsController` | ✅ |
| Parrain | `_selectedParrainId` (dropdown) | ✅ |
| Email | — | ❌ |
| Rôle | — | ❌ |

Le bouton **Annuler** réinitialise tous les contrôleurs à leurs valeurs avant édition.

### `_saveUserInfo()`

Valide que prénom et nom ne sont pas vides, puis met à jour dans `users` :
`prenom`, `nom`, `phone`, `member_since` (format ISO date `YYYY-MM-DD`),
`passions` (null si vide), `parrain_id`.
Met à jour `_user` localement et passe `_isEditing = false`.

### `_buildParrainDropdown()`

`DropdownButtonFormField<String?>` avec un item "Aucun parrain" (`null`) suivi
de tous les adhérents/admins chargés dans `_adherents`.
À la sélection, met à jour `_selectedParrainId` et résout `_selectedParrainName`.

---

## Section Informations professionnelles (`_buildProfessionalInfoSection`)

Visible uniquement pour les rôles `adherent` et `admin`.

### Mode lecture

Affiche les champs non vides via `_InfoItem` + un toggle `Switch` pour contrôler
la visibilité dans l'annuaire (sans passer en mode édition).

### `_toggleShareProInfo()`

Inverse `_user.shareProInfo` et met à jour le champ `share_pro_info` dans Supabase
immédiatement, sans passer par le mode édition.

### Mode édition

| Champ | Contrôleur |
|---|---|
| Entreprise / Organisation | `_companyNameController` |
| Activités / Compétences | `_skillsController` (multilignes) |
| Adresse professionnelle | `_professionalAddressController` |
| Site web / Portfolio | `_websiteController` |

### `_saveProfessionalInfo()`

Met à jour dans `users` : `company_name`, `skills`, `professional_address`,
`website`, `share_pro_info`.
Met à jour `_user` localement et passe `_isEditingPro = false`.

> Le toggle `share_pro_info` est inclus dans la sauvegarde pour rester cohérent
> avec la valeur en mémoire, même si le Switch est accessible hors mode édition.

---

## Section Badges (`BadgesSection`)

Widget externe (`badges_widget.dart`) affiché uniquement pour `adherent` et `admin`.
Reçoit une `Map` avec les données de l'utilisateur : `id`, `prenom`, `nom`,
`phone`, `passions`, `member_since`.

---

## Section Sécurité (`_buildSecuritySection`)

Deux entrées `ListTile` :

| Entrée | Action |
|---|---|
| Modifier le mot de passe | Ouvre `_showChangePasswordDialog()` |
| Vérification à deux facteurs | Affiche un SnackBar "Fonctionnalité à venir" |

### `_showChangePasswordDialog()`

Dialog `StatefulBuilder` avec trois `TextField` (mot de passe actuel, nouveau,
confirmation), chacun avec un toggle de visibilité (œil).

Flux de validation :
1. Vérifie que tous les champs sont remplis
2. Vérifie que le nouveau mot de passe fait au moins 6 caractères
3. Vérifie la correspondance nouveau / confirmation
4. **Ré-authentifie** l'utilisateur via `signInWithPassword` (obligatoire par
   Supabase avant un changement de mot de passe)
5. Applique le changement via `auth.updateUser(UserAttributes(password: newPwd))`

Gestion des erreurs `AuthException` traduite en messages français :

| Code Supabase | Message affiché |
|---|---|
| `invalid_credentials` | Mot de passe actuel incorrect |
| `Password should be at least 6 characters` | Mot de passe trop faible |
| `Email rate limit exceeded` | Trop de tentatives, réessayer plus tard |

Un `LinearProgressIndicator` s'affiche pendant la requête (`isLoading`).
Les contrôleurs sont disposés après fermeture du dialog.

---

## Section Légal (`_buildLegalSection`)

Un `ListTile` ouvrant `_showCGUDialog()`.

### `_showCGUDialog()`

Appelle `CGUService.hasUserAcceptedCGU(_user.uid)` pour déterminer si l'utilisateur
a déjà accepté les CGU, puis ouvre `CGUAcceptanceDialog` avec le flag `alreadyAccepted`.
Le callback `onAccepted` ferme le dialog et affiche un SnackBar de confirmation.

---

## Widget utilitaire : `_InfoItem`

Widget stateless réutilisé dans toutes les sections pour afficher un champ en lecture.

| Paramètre | Rôle |
|---|---|
| `icon` | Icône bleue à gauche |
| `label` | Label en `labelSmall` grisé |
| `value` | Valeur en `bodyMedium` semi-gras |
| `isDark` | Adapte les couleurs texte au thème |

---

## Tables et Buckets Supabase

| Ressource | Opérations | Champs concernés |
|---|---|---|
| `users` (table) | SELECT, UPDATE | `prenom`, `nom`, `phone`, `member_since`, `passions`, `parrain_id`, `company_name`, `skills`, `professional_address`, `website`, `share_pro_info`, `photo_url` |
| `avatars` (bucket) | uploadBinary, getPublicUrl | `{uid}_{timestamp}.jpg` |

## Services et widgets externes

| Élément | Rôle |
|---|---|
| `CGUService` | Vérifie l'acceptation des CGU (`hasUserAcceptedCGU`) |
| `CGUAcceptanceDialog` | Dialog de lecture et acceptation des CGU |
| `BadgesSection` | Affichage des badges de gamification |
| `ImagePicker` | Sélection de la photo depuis la galerie |