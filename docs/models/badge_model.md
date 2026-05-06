# Résumé de `badge.dart`

**But :** Définition des types de badges de gamification et de leurs métadonnées.
Fichier purement déclaratif — aucune logique métier, aucun appel réseau.
Utilisé par `BadgesSection` (widget) et `settings_page` / `directory_page_dynamic`
pour l'affichage des badges par utilisateur.

---

## Contenu

### `BadgeType` (enum)

Cinq valeurs identifiant chaque badge de manière typée :

| Valeur | Badge |
|---|---|
| `profilComplet` | Profil complet |
| `fidele` | Fidèle |
| `actif` | Actif |
| `pionnier` | Pionnier |
| `ambassadeur` | Ambassadeur |

---

### `BadgeInfo` (classe immuable)

Regroupe toutes les métadonnées d'affichage d'un badge.
Tous les champs sont `final` et requis ; la classe est déclarée `const`.

| Champ | Type | Rôle |
|---|---|---|
| `type` | `BadgeType` | Référence vers l'enum |
| `label` | `String` | Nom affiché dans l'UI |
| `description` | `String` | Condition d'obtention (sous-titre) |
| `icon` | `IconData` | Icône Material affichée dans le badge |
| `color` | `Color` | Couleur thématique du badge |

---

### `kBadges` (constante globale)

`Map<BadgeType, BadgeInfo>` déclarée `const`, servant de registre central.
Permet d'accéder aux métadonnées d'un badge par son type : `kBadges[BadgeType.actif]`.

| Badge | Icône | Couleur | Condition |
|---|---|---|---|
| Profil complet | `verified_user` | Bleu `#2196F3` | Toutes les infos renseignées |
| Fidèle | `loyalty` | Violet `#9C27B0` | Membre depuis plus d'un an |
| Actif | `local_fire_department` | Orange-rouge `#FF5722` | 10 événements auxquels participé |
| Pionnier | `emoji_events` | Ambre `#FFB300` | Adhérent depuis 2018 (membre fondateur) |
| Ambassadeur | `groups` | Vert `#4CAF50` | A parrainé 2 membres ou plus |

---

## Points d'attention

- Les conditions d'obtention décrites dans `description` sont purement textuelles —
  la logique de calcul (vérifier si un utilisateur a le badge) est implémentée
  dans `BadgesSection`, pas ici.
- `kBadges` est une constante de compilation : aucune valeur ne peut être ajoutée
  ou modifiée à l'exécution. Tout nouveau badge nécessite une mise à jour du code
  source et un nouveau déploiement.
- Le champ `type` dans `BadgeInfo` est redondant avec la clé de la `Map`,
  mais permet d'accéder au type depuis une instance `BadgeInfo` isolée.
