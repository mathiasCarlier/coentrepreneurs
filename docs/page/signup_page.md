```markdown
# Résumé de `signup_page.dart`

**But :** Écran d'inscription permettant à un nouvel utilisateur de créer son compte.
Collecte les informations de base, valide localement, puis délègue la création à
`AuthService.signup`. Après inscription, redirige vers `/home` où l'écran d'attente
d'approbation s'affiche automatiquement.

---

## Architecture générale

```
SignUpPage (StatefulWidget)
└── Body — Card centrée (maxWidth 420)
    └── Form (_formKey)
        ├── TextFormField prénom
        ├── TextFormField nom
        ├── TextFormField email
        ├── TextFormField téléphone
        ├── TextFormField mot de passe (+ toggle visibilité)
        ├── TextFormField confirmation mot de passe
        ├── Affichage erreur (_error)
        └── FilledButton "Créer un compte" → _submit()
```

---

## État local

| Variable | Type | Rôle |
|---|---|---|
| `_formKey` | `GlobalKey<FormState>` | Clé du formulaire pour la validation |
| `_prenomCtrl` | `TextEditingController` | Champ prénom |
| `_nomCtrl` | `TextEditingController` | Champ nom |
| `_emailCtrl` | `TextEditingController` | Champ email |
| `_phoneCtrl` | `TextEditingController` | Champ téléphone |
| `_passwordCtrl` | `TextEditingController` | Champ mot de passe |
| `_confirmPasswordCtrl` | `TextEditingController` | Champ confirmation |
| `_selectedRole` | `UserRole` | Rôle fixe `adherent` (non modifiable par l'UI) |
| `_loading` | `bool` | Verrou pendant l'appel à `AuthService.signup` |
| `_error` | `String?` | Message d'erreur affiché sous le formulaire |
| `_showPassword` | `bool` | Toggle commun aux deux champs mot de passe |

> Le toggle `_showPassword` est partagé entre le champ mot de passe et le champ
> de confirmation — les deux basculent ensemble.

---

## Validation locale

Effectuée par `_formKey.currentState?.validate()` avant tout appel réseau.

| Champ | Règles |
|---|---|
| Prénom | Non vide |
| Nom | Non vide |
| Email | Non vide + regex format `xxx@xxx.xx` |
| Téléphone | Non vide (format non vérifié) |
| Mot de passe | Non vide + longueur ≥ 6 caractères |
| Confirmation | Doit correspondre exactement à `_passwordCtrl.text` |

La touche `done` sur le champ de confirmation déclenche `_submit()` via
`onFieldSubmitted`, sans avoir à toucher le bouton.

---

## `_submit()`

1. Appelle `_formKey.currentState?.validate()` — arrête si invalide
2. Passe `_loading = true` et `_error = null`
3. Appelle `AuthService.signup(email, password, nom, prenom, phone, role)`
4. En cas de succès → `context.go('/home')`
5. En cas d'erreur → stocke dans `_error` (affiché en rouge via `scheme.error`)
6. `finally` : repasse `_loading = false` avec vérification `mounted`

> `AuthService.signup` crée l'entrée dans `auth.users` (Supabase Auth) **et**
> insère la ligne correspondante dans la table `users` avec `approval_status: 'pending'`.
> La page ne gère pas ces détails directement.

---

## Rôle et workflow d'approbation

Le rôle est fixé à `UserRole.adherent` à la construction (`_selectedRole` est une
constante `final` non exposée dans l'UI). L'utilisateur ne peut pas choisir son rôle.

Après inscription :
- L'utilisateur est redirigé vers `/home`
- `home_page` détecte `approval_status != 'approved'` et affiche `_buildPendingApprovalScreen`
- Un admin doit approuver la demande depuis l'onglet Adhésions de `notifications_page`

---

## Navigation

| Déclencheur | Destination |
|---|---|
| Inscription réussie | `context.go('/home')` |
| Lien "Se connecter" | `context.go('/login')` |

La navigation utilise `go_router` (`context.go`) pour remplacer la route courante,
rendant le retour vers `/signup` impossible depuis `/home`.

---

## Services utilisés

| Élément | Rôle |
|---|---|
| `AuthService` | Création du compte Supabase Auth + insertion dans `users` |
```