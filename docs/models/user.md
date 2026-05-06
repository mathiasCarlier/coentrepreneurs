# Résumé de `user.dart`

**But :** Modèle applicatif central représentant un utilisateur de l'application,
avec l'ensemble de ses données personnelles, professionnelles et de rôle.
Utilisé dans toute l'application : `AuthService`, `home_page`, `settings_page`,
`directory_page_dynamic`, `admin_users_page`, etc.

---

## `UserRole` (enum)

| Valeur | Accès |
|---|---|
| `admin` | Accès complet + fonctions d'administration |
| `adherent` | Accès complet à l'application |
| `invite` | Accès limité, en attente d'approbation |

Valeur par défaut à la création : `UserRole.invite`.
Stocké en base comme chaîne simple via `role.toString().split('.').last`
(ex. `'admin'`, `'adherent'`, `'invite'`).

---

## Classe `User`

### Mutabilité

Contrairement aux autres modèles, plusieurs champs sont déclarés **`var`** (mutable)
plutôt que `final`. Cela permet à `settings_page` de les modifier directement
sur l'objet local sans passer systématiquement par `copyWith`.

| Mutabilité | Champs |
|---|---|
| `final` (immuables) | `uid`, `role` |
| Mutables | `email`, `nom`, `prenom`, `phone`, `photoUrl`, `companyName`, `skills`, `professionalAddress`, `website`, `shareProInfo`, `memberSince`, `passions`, `parrainId` |

### Champs

**Identité et authentification**

| Champ | Type | Colonne Supabase | Rôle |
|---|---|---|---|
| `uid` | `String` | `id` | UUID Supabase Auth |
| `email` | `String` | `email` | Email de connexion |
| `role` | `UserRole` | `role` | Rôle applicatif |

**Profil personnel**

| Champ | Type | Colonne Supabase | Défaut |
|---|---|---|---|
| `nom` | `String` | `nom` | — |
| `prenom` | `String` | `prenom` | — |
| `phone` | `String` | `phone` | `''` |
| `photoUrl` | `String?` | `photo_url` | `null` |
| `memberSince` | `DateTime?` | `member_since` | `null` |
| `passions` | `String?` | `passions` | `null` |
| `parrainId` | `String?` | `parrain_id` | `null` |

**Profil professionnel**

| Champ | Type | Colonne Supabase | Défaut |
|---|---|---|---|
| `companyName` | `String?` | `company_name` | `null` |
| `skills` | `String?` | `skills` | `null` |
| `professionalAddress` | `String?` | `professional_address` | `null` |
| `website` | `String?` | `website` | `null` |
| `shareProInfo` | `bool?` | `share_pro_info` | `false` |

---

## Méthodes

### `toMap()`

Sérialisation en **camelCase** (attention : diverge de la convention snake_case
de Supabase). Utilisé principalement pour la communication interne entre services.

> Le rôle est sérialisé via `role.toString().split('.').last` plutôt que
> `role.name` — les deux sont équivalents en Dart 2.15+, mais la forme longue
> peut créer une confusion si le format de `toString()` évolue.

`memberSince` est sérialisé en date seule `YYYY-MM-DD` via `.substring(0, 10)`.

### `User.fromMap(Map)`

Désérialisation depuis une map **camelCase**. Utilise `DateTime.tryParse`
(sans exception) pour `memberSince` — retourne `null` si le format est invalide.

> ⚠️ Les clés de `fromMap` sont en camelCase (`'photoUrl'`, `'companyName'`…)
> alors que Supabase retourne du snake_case (`'photo_url'`, `'company_name'`…).
> La conversion camelCase ↔ snake_case est donc effectuée dans `AuthService`,
> pas dans le modèle.

### `_parseRole(String?)` (statique, privée)

Convertit une chaîne en `UserRole`. Tout rôle non reconnu ou `null` retourne
`UserRole.invite` par défaut (sécurité — accès minimal).

### `copyWith`

Pattern standard de copie immuable sans flag de suppression. Les champs
nullables ne peuvent pas être forcés à `null` via `copyWith` — la mutabilité
directe des champs est utilisée à la place dans `settings_page`.

### `toString()`

Représentation textuelle complète pour le débogage, incluant tous les champs
sauf les listes.

---

## Points d'attention

- **Incohérence camelCase / snake_case** : `toMap()` et `fromMap()` utilisent
  le camelCase alors que Supabase attend du snake_case. La traduction est à la
  charge de `AuthService` — toute utilisation directe de `toMap()` vers Supabase
  sans transformation produirait des colonnes non reconnues.
- **Mutabilité des champs** : la modification directe des champs (ex.
  `_user.prenom = value`) contourne le principe d'immuabilité habituel des
  modèles Flutter — à surveiller si l'état est partagé entre plusieurs widgets.
- **`role` immuable** : le rôle ne peut pas être modifié via `copyWith` ni
  directement — un changement de rôle nécessite de recréer un objet `User`
  complet, ce qui est cohérent avec la sensibilité de ce champ.