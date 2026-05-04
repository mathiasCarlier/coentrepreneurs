# Résumé de `auth_service.dart`

**But :** Service central d'authentification. Fait le pont entre Supabase Auth
(gestion des sessions) et la table `users` (données applicatives enrichies).
Exposé via `Provider` et consommé dans toute l'application.

---

## Interface publique

| Membre | Type | Rôle |
|---|---|---|
| `authStateChanges` | `Stream<User?>` | Stream enrichi des changements d'état auth |
| `authEventChanges` | `Stream<AuthChangeEvent>` | Stream brut des événements Supabase Auth |
| `currentUser` | `Future<User?>` | Utilisateur courant (asynchrone) |
| `isSignedIn` | `bool` | Session active (synchrone, sans appel réseau) |
| `login()` | `Future<User?>` | Connexion email/password |
| `signup()` | `Future<User?>` | Inscription + création entrée `users` |
| `logout()` | `Future<void>` | Déconnexion |
| `sendPasswordResetEmail()` | `Future<void>` | Envoi email de réinitialisation |

---

## `authStateChanges`

Stream construit sur `_supabase.auth.onAuthStateChange` via `.asyncMap`.
Pour chaque événement :
1. Ignore `AuthChangeEvent.passwordRecovery` → émet `null` (évite un accès
   non voulu à `/home` lors d'un reset de mot de passe)
2. Si la session est `null` → émet `null`
3. Sinon → appelle `_buildUser()` pour enrichir avec les données de `users`

---

## `login(email, password)`

1. Appelle `signInWithPassword`
2. Vérifie `blocked == true` dans `users` — si bloqué : `signOut()` + exception
3. Appelle `_buildUser()` pour retourner un `User` enrichi
4. Les `AuthException` sont traduits en messages français via `_handleAuthException`

---

## `signup(...)`

1. Valide localement que tous les champs sont non vides et que le mot de passe
   fait au moins 6 caractères
2. Appelle `auth.signUp`
3. Fait un **upsert** dans `users` avec les champs de base + `approval_status: 'pending'`

> Un trigger Supabase crée déjà une ligne minimale à la création du compte Auth —
> l'upsert complète cette ligne avec les données du formulaire d'inscription.

Retourne un `User` construit directement (sans `_buildUser`) car les données
sont déjà connues localement.

---

## `sendPasswordResetEmail(email)`

Délègue à `auth.resetPasswordForEmail`. Les erreurs sont traduites via
`_handleAuthException`.

---

## `logout()`

Appelle `auth.signOut`. Les erreurs sont encapsulées dans une exception
avec message français.

---

## Helpers privés

### `_buildUser(supabaseUser)`

Construit un `user_model.User` enrichi depuis la table `users` via `_getUserData`.
En cas d'erreur réseau ou de données manquantes, retourne un `User` minimal
(uid + email, rôle `invite`) pour ne pas bloquer le stream.

> Les champs `memberSince`, `passions` et `parrainId` ne sont pas chargés ici —
> `_buildUser` est optimisé pour le stream d'auth. `settings_page` recharge
> ces données via `_loadUserData()` à l'ouverture.

### `_getUserData(uid)`

Requête `SELECT *` sur `users` avec `.maybeSingle()`. Retourne `null` en cas
d'erreur (loguée en debug) sans propager l'exception.

### `_parseRole(String?)` (statique)

Identique à `user.dart` — convertit une chaîne en `UserRole`.
Tout rôle non reconnu ou `null` → `UserRole.invite`.

### `_handleAuthException(AuthException)` (statique)

Traduit les messages d'erreur Supabase Auth en messages français lisibles.

| Message Supabase | Message retourné |
|---|---|
| `invalid_credentials` | Email ou mot de passe incorrect |
| `email not confirmed` | Confirmation email requise |
| `already been registered` | Email déjà utilisé |
| `password should be at least` | Mot de passe trop faible |
| `unable to validate email address` | Email invalide |
| `too many requests` | Trop de tentatives |
| `network` | Erreur réseau |
| Autre | Message brut préfixé |

---

## `GoRouterRefreshStream`

Classe utilitaire `ChangeNotifier` qui souscrit à un `Stream` et appelle
`notifyListeners()` à chaque émission. Utilisée pour brancher
`authStateChanges` sur le mécanisme de refresh de `GoRouter`, déclenchant
une réévaluation des routes à chaque changement d'état d'authentification.

---

## Table Supabase

| Table | Opérations | Champs concernés |
|---|---|---|
| `users` | SELECT (`_getUserData`), UPSERT (`signup`) | `id`, `email`, `nom`, `prenom`, `phone`, `role`, `photo_url`, `company_name`, `skills`, `professional_address`, `website`, `share_pro_info`, `blocked`, `approval_status` |
```