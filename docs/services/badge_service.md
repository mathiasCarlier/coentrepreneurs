# Résumé de `badge_service.dart`

**But :** Service de calcul et de chargement des badges de gamification.
Effectue les requêtes Supabase nécessaires, puis délègue le calcul d'éligibilité
à une méthode pure. Utilisé par `BadgesSection` (widget).

---

## Classe `BadgeData`

Conteneur immuable (`const`) retourné par `loadBadges`.

| Champ | Type | Rôle |
|---|---|---|
| `earned` | `List<BadgeType>` | Badges obtenus par l'utilisateur |
| `eventsAttended` | `int` | Nombre d'événements confirmés (donnée brute) |
| `parrainages` | `int` | Nombre de membres parrainés (donnée brute) |

Les champs `eventsAttended` et `parrainages` sont exposés pour permettre
l'affichage de la progression dans `BadgesSection` sans refaire les requêtes.

---

## `BadgeService`

Classe stateless — toutes les méthodes sont `static`. Pas d'instanciation requise.

### `loadBadges(userData)` — async

Point d'entrée principal. Accepte une `Map<String, dynamic>` compatible avec
les données brutes Supabase (clé `'id'`) ou l'objet `User` sérialisé (clé `'uid'`).

Flux d'exécution :
1. Extrait l'UID via `userData['id'] ?? userData['uid']`
2. Si `null` → retourne un `BadgeData` vide immédiatement
3. Requête `registrations` : compte les lignes avec `user_id == uid` et `status == 'confirmed'`
4. Requête `users` : compte les lignes avec `parrain_id == uid`
5. Appelle `computeBadges()` avec les résultats
6. Retourne un `BadgeData` complet

> Les deux requêtes sont effectuées **séquentiellement** (pas de `Future.wait`).
> Un refactoring en parallèle réduirait le temps de chargement.

### `computeBadges({userData, eventsAttended, parrainages})` — synchrone, pure

Méthode pure sans appel réseau — testable unitairement sans mock Supabase.
Évalue les conditions de chaque badge dans l'ordre :

| Badge | Condition |
|---|---|
| `profilComplet` | `prenom`, `nom`, `phone`, `passions` non vides **ET** `member_since` non null |
| `fidele` | `member_since` parsé + ancienneté ≥ 1 an (`inDays / 365`) |
| `pionnier` | `member_since.year <= 2018` |
| `actif` | `eventsAttended >= 10` |
| `ambassadeur` | `parrainages >= 2` |

> `fidele` et `pionnier` partagent le même parsing de `member_since` — si le
> champ est non null mais mal formaté, `DateTime.tryParse` retourne `null` et
> les deux badges sont silencieusement ignorés.

---

## Tables Supabase

| Table | Opération | Filtre | Donnée extraite |
|---|---|---|---|
| `registrations` | SELECT `id` | `user_id == uid` + `status == 'confirmed'` | Nombre de participations confirmées |
| `users` | SELECT `id` | `parrain_id == uid` | Nombre de membres parrainés |

---

## Points d'attention

- Le calcul de `fidele` utilise `inDays / 365` (division entière réelle) sans
  tenir compte des années bissextiles — légère imprécision acceptable.
- Les deux requêtes Supabase sont séquentielles — un `Future.wait` les paralléliserait.
- `computeBadges` est `static` et pure : idéal pour des tests unitaires sans
  infrastructure Supabase.
- La double clé `'id' ?? 'uid'` dans `loadBadges` assure la compatibilité entre
  les données brutes Supabase (`'id'`) et l'objet `User` sérialisé (`'uid'`).