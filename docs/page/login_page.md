# Résumé de `login_page.dart`

**But :** Écran de connexion de l'application. Propose un formulaire email/mot de passe
avec validation locale, récupération de mot de passe et toggle de thème.
Point d'entrée utilisateur avant redirection vers `/home`.

---

## Architecture générale

LoginPage (StatefulWidget)
├── AppBar
│   └── Toggle thème (Consumer<ThemeNotifier>)
└── Body — Card centrée (maxWidth 420)
└── Form (_formKey)
├── TextFormField email
├── TextFormField mot de passe (+ toggle visibilité)
├── TextButton "Mot de passe oublié ?"
│   └── _showForgotPasswordDialog()
├── Affichage erreur (_error)
└── FilledButton "Se connecter" → _submit()

---

## État local

| Variable | Type | Rôle |
|---|---|---|
| `_formKey` | `GlobalKey<FormState>` | Clé du formulaire pour la validation |
| `_emailCtrl` | `TextEditingController` | Valeur du champ email |
| `_passwordCtrl` | `TextEditingController` | Valeur du champ mot de passe |
| `_loading` | `bool` | Verrou pendant l'appel à `AuthService.login` |
| `_error` | `String?` | Message d'erreur affiché sous le formulaire |
| `_showPassword` | `bool` | Toggle de visibilité du mot de passe |

---

## Validation locale

Effectuée par le `Form` via `_formKey.currentState?.validate()` avant tout
appel réseau.

| Champ | Règles |
|---|---|
| Email | Non vide + regex format `xxx@xxx.xx` |
| Mot de passe | Non vide + longueur minimale 6 caractères |

Les deux champs déclarent des `autofillHints` pour le gestionnaire de mots
de passe du navigateur/OS (`AutofillHints.username`, `AutofillHints.email`,
`AutofillHints.password`).

La touche `done` du clavier sur le champ mot de passe déclenche `_submit()`
via `onFieldSubmitted`, évitant d'avoir à tapper le bouton.

---

## `_submit()`

1. Appelle `_formKey.currentState?.validate()` — arrête si invalide
2. Passe `_loading = true` et `_error = null`
3. Appelle `AuthService.login(email, password)`
4. En cas de succès → `context.go('/home')`
5. En cas d'erreur → stocke le message dans `_error` (affiché en rouge)
6. `finally` : repasse `_loading = false` avec vérification `mounted`

> `AuthService.login` centralise la traduction des erreurs Supabase Auth
> (ex. blocage, mauvaises credentials) — `login_page` ne traite pas les
> codes d'erreur bruts.

---

## `_showForgotPasswordDialog()`

Dialog `StatefulBuilder` (état local `successMessage` / `errorMessage`)
avec un `TextFormField` email pré-rempli avec la valeur du champ principal
si elle est déjà saisie.

Flux :
1. Valide l'email via la même regex que le formulaire principal
2. Appelle `AuthService.sendPasswordResetEmail(email)`
3. En cas de succès : affiche `successMessage` et désactive le bouton "Envoyer"
   (évite les doubles envois)
4. En cas d'erreur : affiche `errorMessage` en rouge

Le contrôleur `emailCtrl` est disposé manuellement après fermeture du dialog.

---

## Navigation

| Déclencheur | Destination |
|---|---|
| Connexion réussie | `context.go('/home')` |
| Lien "Créer un compte" | `context.go('/signup')` |

La navigation utilise `go_router` (`context.go`) pour remplacer la route
courante dans la pile (pas de retour possible vers `/login` depuis `/home`).

---

## Services et widgets externes

| Élément | Rôle |
|---|---|
| `AuthService` | Login + envoi de l'email de réinitialisation |
| `ThemeNotifier` | Toggle thème clair/sombre dans l'AppBar |