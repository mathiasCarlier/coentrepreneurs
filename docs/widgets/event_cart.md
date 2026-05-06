# Résumé de `event_card_avec_inscription.dart`

**But :** Carte interactive affichant une rencontre avec les actions disponibles
selon l'état de l'utilisateur. Widget central de l'application, utilisé dans
`home_page`, `all_events_page` et `notifications_page`.

---

## Architecture

```
EventCard (StatefulWidget)
├── MouseRegion + AnimationController  — élévation au survol (web)
├── Card + InkWell
│   ├── [isFinished]     _buildFinishedView()
│   ├── [isDeclined]     _buildDeclinedView()
│   ├── [isConfirmed]    _buildConfirmedView()
│   ├── [isRegistered]   _buildInscribedView()
│   └── [none]           _buildUnregisteredView()
└── Helpers
    ├── _buildEventImage()
    ├── _buildDetailRow()
    ├── _buildLocationRow()
    └── _buildSummarySection() → _showSummaryBottomSheet()
```

---

## Props

| Paramètre | Type | Défaut | Rôle |
|---|---|---|---|
| `event` | `Event` | — | Données de la rencontre |
| `isDark` | `bool` | — | Thème courant |
| `currentUser` | `User?` | `null` | Utilisateur connecté (null = lecture seule) |
| `showParticipantCount` | `bool` | `true` | Affichage du compteur (non utilisé dans les vues actuelles) |
| `onTap` | `VoidCallback?` | `null` | Action optionnelle au tap sur la carte |

---

## État local

| Variable | Type | Rôle |
|---|---|---|
| `_controller` | `AnimationController` | Animation d'élévation au survol |
| `_elevation` | `Animation<double>` | Interpolation 2 → 12 en `easeInOut` |
| `_isLoading` | `bool` | Verrou pendant les opérations async |

### Getters calculés (sans état stocké)

| Getter | Calcul |
|---|---|
| `_isUserInscribed` | `event.isUserRegistered(uid)` |
| `_isUserConfirmed` | `event.isUserConfirmed(uid)` |
| `_isUserDeclined` | `event.isUserDeclined(uid)` |

---

## Priorité des vues (ordre d'évaluation)

```
isFinished  → _buildFinishedView (hors du switch)
isDeclined  → _buildDeclinedView     (priorité 1)
isConfirmed → _buildConfirmedView    (priorité 2)
isRegistered→ _buildInscribedView    (priorité 3)
[aucun]     → _buildUnregisteredView (priorité 4)
```

---

## Vues détaillées

### `_buildFinishedView`
Date + thème + badge "Terminé" + bouton "Voir le compte-rendu" si `hasSummary`.

### `_buildUnregisteredView`
Détails complets (date, thème, intervenant, entreprise, lieu).
Boutons **"Je viens"** (vert) et **"Je ne viens pas"** (rouge).
Bannière orange si inscriptions fermées (`isStarted`).
Bouton désactivé si `isStarted` ou `isFull`.

### `_buildDeclinedView`
Vue compacte : date + badge "Refusé" rouge + bouton **"Annuler le refus"**.

### `_buildInscribedView`
Date + thème + badge "Je suis inscrit" (orange avant début, violet pendant).
Lieu cliquable.
Bouton **"Inviter quelqu'un"** (avant début) ou mode confirmation (pendant).
Bouton collation si `event.hasCollation`.

### `_buildConfirmedView`
Date + thème + badge "Présent" orange.
Lieu cliquable.
Bannière verte "Votre présence est confirmée".
Bandeau orange "Repas réservé" si collation choisie.

---

## Actions

### `_toggleRegistration()`

Logique d'inscription/désinscription :
1. Vérifie l'utilisateur connecté
2. Si inscrit + `isStarted` → erreur (désinscription impossible)
3. Si inscrit → `unregisterUserFromEvent`
4. Si non inscrit + `isStarted` → erreur (inscriptions fermées)
5. Si non inscrit + `isFull` → erreur (complet)
6. Sinon → `registerUserToEvent` + délai 500ms + `_showInvitationDialog`

### `_declineEvent()` / `_cancelDecline()`

Délèguent respectivement à `RegistrationService.declineEvent` et `cancelDecline`.

### `_showCollationSelection()`

Ouvre `showCollationDialog` (widget externe), récupère le choix booléen,
puis appelle `RegistrationService.saveCollationChoice`.

### `_openLocation()`

Appelle `LocationService.openMaps(event.lieu)` pour ouvrir Google Maps.

### `_showInvitationDialog()` + `_sendInvitations()`

Ouvre `showInvitationDialog` (widget externe), récupère la liste d'invités
(`List<Map<String, String>>`), puis appelle
`InvitationService.createInvitationsWithUsers`.

---

## Helpers de rendu

### `_buildEventImage()`

Affiche `event.imageUrl` avec `BoxFit.fitWidth` si non nulle.
`errorBuilder` retourne `SizedBox.shrink()` silencieusement.

### `_buildDetailRow(icon, label, value, isDefined)`

Icône bleue si défini, orange si non défini. Texte en italique si `!isDefined`.

### `_buildLocationRow(value, isDefined)`

Identique à `_buildDetailRow` mais avec `GestureDetector` → `_openLocation()`
et texte souligné + indication "🔗 Cliquer pour ouvrir Maps" si `isDefined`.

### `_buildSummarySection()` + `_showSummaryBottomSheet()`

Bouton teal "Voir le compte-rendu" ouvrant un `DraggableScrollableSheet`
(60–95 % de l'écran) avec rendu `MarkdownBody` du `event.summary`.

---

## `didUpdateWidget`

Déclenche `setState` si `isDark`, `currentUser.uid` ou `event.id` changent —
assure la cohérence visuelle sans recréer le widget.

---

## Services utilisés

| Service | Méthodes appelées |
|---|---|
| `RegistrationService` | `registerUserToEvent`, `unregisterUserFromEvent`, `declineEvent`, `cancelDecline`, `saveCollationChoice` |
| `InvitationService` | `createInvitationsWithUsers` |
| `LocationService` | `openMaps` |
```