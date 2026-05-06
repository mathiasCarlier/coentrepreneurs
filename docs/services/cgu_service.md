# Résumé de `cgu_service.dart`

**But :** Service responsable de la vérification et de l'enregistrement de
l'acceptation des CGU par utilisateur et par version. Utilisé par `home_page`,
`settings_page` et `CGUAcceptanceDialog`.

---

## Constante de version

```dart
static const String currentCGUVersion = '1.0';
```

Référence centrale pour toutes les opérations du service. Incrémenter cette
valeur force tous les utilisateurs à ré-accepter les nouvelles CGU à leur
prochaine connexion — `home_page` détecte l'absence d'acceptation pour la
version courante et ouvre `CGUAcceptanceDialog`.

---

## `hasUserAcceptedCGU(userId)`

Requête `SELECT` sur `cgu_acceptances` filtrée sur `(user_id, cgu_version)` via
`.maybeSingle()`. Désérialise le résultat via `CGUAcceptance.fromMap` et retourne
`acceptance.hasAccepted`.

**Comportement en cas d'erreur réseau :** retourne `true` pour ne pas bloquer
l'accès à l'application sur un problème de connectivité temporaire.

> Ce choix est conservateur côté UX mais crée un risque théorique d'accès sans
> acceptation valide en cas d'erreur persistante.

---

## `acceptCGU(userId)`

Stratégie **select → update ou insert** (pas d'upsert) pour contourner les
limitations de PostgREST avec les contraintes uniques composites et les
politiques RLS.

```
1. SELECT id WHERE (user_id, cgu_version) → maybeSingle
   ├── Existe → UPDATE has_accepted + accepted_date
   └── Absent → INSERT nouvel enregistrement
```

Les erreurs sont loguées en debug et **re-propagées** (`rethrow`) — contrairement
à `hasUserAcceptedCGU` qui absorbe les erreurs, `acceptCGU` les laisse remonter
pour que l'appelant puisse afficher un message d'erreur à l'utilisateur.

---

## `cguContent`

Constante `static const String` contenant le texte intégral des CGU en français
(10 articles). Affichée dans `CGUAcceptanceDialog` et consultable depuis
`settings_page`.

Sections couvertes : objet, accès, règles de conduite, éthique, contenus
publiés, données personnelles (RGPD), responsabilité, sanctions, évolution
des CGU, acceptation.

---

## Table Supabase

| Table | Opérations | Champs concernés |
|---|---|---|
| `cgu_acceptances` | SELECT, UPDATE, INSERT | `user_id`, `has_accepted`, `accepted_date`, `cgu_version` |

Contrainte unique sur `(user_id, cgu_version)` — garantit une seule ligne
par utilisateur et par version de CGU.

---

## Points d'attention

- Le fallback `return true` dans `hasUserAcceptedCGU` en cas d'erreur réseau
  est un choix délibéré côté UX — à réévaluer si une conformité stricte est requise.
- `currentCGUVersion` est une constante de compilation : toute modification
  nécessite un redéploiement de l'application.
- Le texte des CGU (`cguContent`) est embarqué dans le code source — pas de
  chargement dynamique depuis Supabase. Une mise à jour du texte sans changement
  de version ne serait pas détectée par le système.