# Résumé de `notification_service.dart` (+ web + stub)

**But :** Gestion des push notifications web (abonnement/désabonnement).
Implémenté via un pattern de compilation conditionnelle Flutter pour isoler
le code JS interop du code mobile.

---

## Architecture — trois fichiers

```
notification_service.dart          — Façade unique consommée par l'app
├── notification_service_stub.dart — Implémentation mobile (no-op)
└── notification_service_web.dart  — Implémentation web (JS interop)
```

La sélection de l'implémentation est effectuée à la **compilation** via
l'import conditionnel :
```dart
import 'notification_service_stub.dart'
    if (dart.library.js_interop) 'notification_service_web.dart';
```
Sur mobile : `stub` est chargé. Sur web : `web` est chargé.

---

## `NotificationService` (façade)

Singleton `factory` avec constructeur `_internal()`.

| Méthode | Comportement |
|---|---|
| `initialize(userId)` | No-op si `!kIsWeb`, sinon délègue à `initializeWeb(userId)` |
| `deleteSubscription()` | No-op si `!kIsWeb`, sinon délègue à `deleteSubscriptionWeb()` |

Consommé dans `home_page` :
- `initialize` : appelé après vérification du statut `'approved'` de l'utilisateur
- `deleteSubscription` : appelé avant `auth.logout()`

---

## `notification_service_stub.dart`

Deux fonctions vides, signatures identiques à la version web.
Compilé sur Android et iOS — garantit que l'app ne plante pas si le code
appelle `initializeWeb` ou `deleteSubscriptionWeb` sur mobile.

```dart
Future<void> initializeWeb(String userId) async {}
Future<void> deleteSubscriptionWeb() async {}
```

---

## `notification_service_web.dart`

Implémentation web avec interopérabilité JavaScript via `dart:js_interop`.

### Constante VAPID

```dart
const String _vapidPublicKey = 'BH-mcoCn...';
```

Clé publique VAPID utilisée pour identifier le serveur de push auprès du
navigateur. Doit correspondre à la clé privée configurée côté serveur.

### Fonctions JS exposées

```dart
@JS('_pushUtils.subscribe')
external JSPromise<JSString> _jsPushSubscribe(JSString vapidKey);

@JS('_pushUtils.unsubscribe')
external JSPromise<JSString> _jsPushUnsubscribe();
```

Pont vers les fonctions JavaScript `window._pushUtils.subscribe` et
`window._pushUtils.unsubscribe`, définies dans le fichier JS embarqué
dans `index.html`. Le résultat est un JSON sérialisé retourné sous forme
de `JSString`.

### `initializeWeb(userId)`

Guard `_initialized` (variable de module) pour éviter une double souscription.

Flux :
1. Appelle `_jsPushSubscribe(vapidKey)` → JSON avec `endpoint` et `keys`
2. Vérifie l'absence de champ `error` dans le résultat
3. Extrait `endpoint`, `p256dh`, `auth`
4. UPSERT dans `push_subscriptions` avec `onConflict: 'endpoint'`
5. Passe `_initialized = true`

Les erreurs sont loguées en debug sans être propagées.

### `deleteSubscriptionWeb()`

1. Récupère l'UID courant
2. Cherche l'`endpoint` dans `push_subscriptions` (`.limit(1)`)
3. DELETE la ligne correspondante
4. Appelle `_jsPushUnsubscribe()` côté JS
5. Remet `_initialized = false`

---

## Table Supabase

| Table | Opérations | Champs concernés |
|---|---|---|
| `push_subscriptions` | UPSERT, SELECT, DELETE | `user_id`, `endpoint`, `p256dh`, `auth` |

Contrainte unique sur `endpoint` — un même endpoint ne peut pas être
enregistré deux fois, même pour des utilisateurs différents.

---

## Points d'attention

- `_initialized` est une variable de **module** (niveau fichier, pas instance) —
  partagée entre toutes les instances, ce qui est cohérent avec le pattern singleton.
- Le bridge JS (`_pushUtils`) doit être défini dans `web/index.html` avant le
  démarrage de Flutter — une absence de définition lèverait une exception à l'appel.
- `deleteSubscriptionWeb` ne vérifie pas `_initialized` avant d'agir —
  peut être appelé même si l'abonnement n'a jamais été initialisé.
- Les erreurs des deux méthodes web sont absorbées silencieusement (log debug
  uniquement) pour ne pas bloquer la connexion ou la déconnexion.
```