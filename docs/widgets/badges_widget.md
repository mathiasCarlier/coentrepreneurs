Résumé de `badges_widget.dart`

**But :** Widget affichant la section badges de gamification d'un utilisateur.
Charge les données via `BadgeService`, affiche tous les badges (obtenus et
verrouillés) dans un `Wrap`. Utilisé dans `settings_page` et `directory_page_dynamic`.

---

## Architecture

```
BadgesSection (StatefulWidget)
└── FutureBuilder<BadgeData>
    └── Wrap
        └── _BadgeChip (par BadgeType)
```

---

## `BadgesSection`

### Props

| Paramètre | Type | Rôle |
|---|---|---|
| `userData` | `Map<String, dynamic>` | Données brutes de l'utilisateur (table `users`) |

### Initialisation

`_future` est créé dans `initState` via `BadgeService.loadBadges(widget.userData)`.
Le `Future` est mis en cache — il n'est pas recréé à chaque `build`, évitant
des requêtes Supabase inutiles lors des rebuilds.

### Affichage

`FutureBuilder<BadgeData>` avec deux états :
- `waiting` → `CircularProgressIndicator` centré
- Données disponibles → `Wrap` de `_BadgeChip` pour **tous** les `BadgeType`

Tous les badges sont toujours affichés (obtenus et verrouillés) — `BadgeType.values`
est itéré en entier. L'état obtenu/verrouillé est déterminé par
`earned.contains(type)`.

Le conteneur a un fond ambre teinté avec bordure ambre, adapté au thème
clair/sombre.

---

## `_BadgeChip`

Widget stateless représentant un badge individuel.

### Props

| Paramètre | Type | Rôle |
|---|---|---|
| `info` | `BadgeInfo` | Métadonnées du badge (depuis `kBadges`) |
| `earned` | `bool` | Badge obtenu ou verrouillé |
| `isDark` | `bool` | Adaptation au thème |

### Apparence selon l'état

| Élément | Obtenu | Verrouillé |
|---|---|---|
| Icône | `info.icon` (couleur du badge) | `Icons.lock_outline` (gris) |
| Label | Gras, couleur du badge | Normal, gris |
| Fond | Couleur badge à 15–25 % d'opacité | Gris clair/sombre |
| Bordure | Couleur badge à 60 % d'opacité | Transparente |

### Tooltip

`Tooltip` wrappant l'ensemble du chip — affiche `info.description`
(condition d'obtention) au survol ou appui long.

---

## Points d'attention

- `_future` est initialisé dans `initState` et non dans `build` —
  correct pour éviter les rechargements intempestifs.
- Si `userData` change (ex. mise à jour du profil), le `Future` n'est
  **pas** recréé automatiquement — un `didUpdateWidget` avec comparaison
  serait nécessaire pour forcer le rechargement.
- Les erreurs de `BadgeService.loadBadges` ne sont pas gérées dans le
  `FutureBuilder` — `snapshot.hasError` n'est pas traité, le widget
  affiche simplement zéro badge en cas d'échec.
