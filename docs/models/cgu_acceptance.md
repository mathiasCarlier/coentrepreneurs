```markdown
# Résumé de `cgu_acceptance.dart`

**But :** Modèle de données représentant l'acceptation des CGU par un utilisateur.
Sert d'interface entre Supabase (table `cgu_acceptances`) et le code Dart,
utilisé par `CGUService` pour les opérations de lecture et d'écriture.

---

## Classe `CGUAcceptance`

### Champs

| Champ | Type | Colonne Supabase | Rôle |
|---|---|---|---|
| `userId` | `String` | `user_id` | UUID de l'utilisateur |
| `hasAccepted` | `bool` | `has_accepted` | Statut d'acceptation |
| `acceptedDate` | `DateTime` | `accepted_date` | Date et heure de l'acceptation |
| `cguVersion` | `String` | `cgu_version` | Version des CGU acceptées |

### Méthodes

**`toMap()`** — Sérialisation pour Supabase.
Convertit `acceptedDate` en chaîne ISO 8601 via `toIso8601String()`.

**`fromMap(Map)`** — Désérialisation depuis Supabase.
Parse `accepted_date` via `DateTime.parse()`. Lève une exception si le format
est invalide (pas de gestion d'erreur explicite — supposé valide en base).

**`copyWith(...)`** — Copie immuable avec champs sélectifs modifiés.
Suit le pattern standard Flutter pour les modèles de données.

---

## Contrainte Supabase et stratégie d'écriture

La table `cgu_acceptances` a une contrainte unique sur `(user_id, cgu_version)`,
empêchant les doublons par utilisateur et par version.

`CGUService` utilise une logique **select → update ou insert** (et non un upsert
direct) pour contourner les limitations de PostgREST/RLS avec cette contrainte :
- Si une ligne existe pour `(user_id, cgu_version)` → `UPDATE`
- Sinon → `INSERT`

---

## Points d'attention

- `fromMap` utilise `DateTime.parse` sans `tryParse` — une valeur nulle ou mal
  formatée en base lèverait une exception non gérée.
- La version des CGU (`cguVersion`) doit être synchronisée avec la constante
  définie dans `CGUService` (`currentCGUVersion`) lors de toute mise à jour
  des conditions d'utilisation.
- Le modèle ne stocke pas d'historique des acceptations — seule la ligne
  `(user_id, cgu_version)` la plus récente est conservée par version.
```