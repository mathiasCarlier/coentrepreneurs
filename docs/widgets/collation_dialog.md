```markdown
# Résumé de `cgu_acceptance_dialog.dart`

**But :** Dialog de lecture et d'acceptation des CGU. Impose la lecture du texte
complet avant d'autoriser l'acceptation. Fonctionne en deux modes : première
acceptation (lecture obligatoire) et consultation ultérieure (lecture seule).
Utilisé par `home_page` et `settings_page`.

---

## Props

| Paramètre | Type | Défaut | Rôle |
|---|---|---|---|
| `onAccepted` | `VoidCallback` | — | Callback déclenché après acceptation réussie |
| `alreadyAccepted` | `bool` | `false` | Mode consultation (pas de checkbox ni de bouton Refuser) |
| `userId` | `String?` | `null` | UID pour persister via `CGUService.acceptCGU` (optionnel) |

---

## État local

| Variable | Type | Rôle |
|---|---|---|
| `_hasReadCGU` | `bool` | Déverrouille la checkbox (scroll ≥ 90 % ou `alreadyAccepted`) |
| `_acceptsCGU` | `bool` | État de la checkbox d'acceptation |
| `_scrollController` | `ScrollController` | Suivi de la progression de lecture |
| `_scrollPercentage` | `double` | Pourcentage de scroll (0–100) |

---

## Mécanique de lecture obligatoire

### `_updateScrollPercentage()`

Listener sur `_scrollController` calculant :
```
scrollPercentage = (offset / maxScrollExtent) * 100
```

Seuil de lecture : **90 %** → passe `_hasReadCGU = true`.
Cas particulier : si `maxScrollExtent == 0` (texte trop court pour scroller),
`_hasReadCGU` est immédiatement `true`.

La checkbox reste **désactivée** (`enabled: false`) tant que `_hasReadCGU` est `false`.

---

## Modes d'affichage

### Mode première acceptation (`alreadyAccepted: false`)

| Élément | Comportement |
|---|---|
| Icône header | `Icons.info_outline` bleu |
| Barre de progression | `LinearProgressIndicator` en bas de la zone de texte |
| Message de progression | Ambre (< 90 %) → vert (≥ 90 %) avec pourcentage |
| Checkbox | Désactivée jusqu'à `_hasReadCGU`, activée ensuite |
| Boutons | "Refuser" (`pop(false)`) + "Accepter" (désactivé si `!_acceptsCGU`) |

### Mode consultation (`alreadyAccepted: true`)

| Élément | Comportement |
|---|---|
| Icône header | `Icons.check_circle` vert |
| Sous-titre | "Vous avez déjà accepté..." |
| `_hasReadCGU` | `true` dès `initState` |
| Barre / message / checkbox | Masqués |
| Bouton unique | "Retour" (`pop()` sans valeur) |

---

## Flux d'acceptation

Utilisateur scrolle ≥ 90%
  → _hasReadCGU = true
  → Checkbox activée
  → Utilisateur coche
  → Bouton "Accepter" activé
  → Tap "Accepter"
      ├── Si userId != null → CGUService.acceptCGU(userId)
      ├── navigator.pop(true)
      └── widget.onAccepted()

Tap "Refuser"
  └── navigator.pop(false)
      → Géré par l'appelant via .then((accepted) { ... })

---

## Layout adaptatif

- `Dialog` avec `insetPadding` fixe (16px horizontal)
- Largeur max 600 px sur écran > 800 px, pleine largeur sinon
- Zone de texte des CGU : hauteur max **300 px** (mobile) / **400 px** (desktop)
- `SingleChildScrollView` wrappant l'ensemble du dialog pour éviter
  un overflow sur petits écrans

---

## Points d'attention

- `CGUService.acceptCGU` est appelé **dans le dialog** si `userId` est fourni,
  mais `home_page` appelle aussi `CGUService.acceptCGU` dans son `onAccepted`
  callback — risque de double appel si `userId` est passé depuis `home_page`.
  Vérifier la cohérence à l'usage.
- Les erreurs de `acceptCGU` sont loguées en debug mais non propagées —
  le dialog se ferme même si la persistance échoue.
- `_scrollController` est proprement disposé dans `dispose()` avec retrait
  du listener.
