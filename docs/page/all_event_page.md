# Résumé de `all_events_page.dart`

**But :** Page calendrier affichant toutes les rencontres de l'association.
Permet de naviguer mois par mois et de consulter les événements d'un jour
sélectionné. Reçoit l'utilisateur courant en paramètre pour l'affichage
des cartes d'inscription.

---

## Architecture générale

AllEventsPage (StatefulWidget)
├── StreamBuilder → EventService.getAllEventsStream()
│   ├── TableCalendar<Event>     — calendrier mensuel avec marqueurs
│   └── ListView
│       └── EventCard            — widget externe (carte + inscription)

---

## État local

| Variable | Type | Rôle |
|---|---|---|
| `_eventService` | `EventService` | Source du stream Realtime |
| `_focusedDay` | `DateTime` | Mois affiché dans le calendrier |
| `_selectedDay` | `DateTime?` | Jour sélectionné (initialisé à `DateTime.now()`) |

---

## Données

### Stream

`EventService.getAllEventsStream()` fournit un `Stream<List<Event>>` Realtime
sur la table `events`. Toutes les rencontres sont chargées en une seule fois,
sans filtre par date — le filtrage est effectué côté Dart.

### `_normalise(DateTime)`

Supprime la composante heure d'une date (`DateTime(year, month, day)`) pour
produire une clé cohérente, indépendante de l'heure stockée en base.

### `_buildEventMap(List<Event>)`

Construit une `Map<DateTime, List<Event>>` à partir de la liste brute.
Chaque clé est une date normalisée ; plusieurs événements peuvent partager
la même clé si plusieurs rencontres sont prévues le même jour.

---

## Composants détaillés

### `TableCalendar<Event>`

Calendrier mensuel (package `table_calendar`) configuré en français (`locale: 'fr_FR'`).

| Paramètre | Valeur |
|---|---|
| Format | Mensuel fixe (bouton de format masqué) |
| Plage | 2020 → 2030 |
| Premier jour | Lundi (`StartingDayOfWeek.monday`) |
| `eventLoader` | Retourne `eventMap[_normalise(day)] ?? []` |
| Marqueurs | Points oranges, max 3 par jour (`markersMaxCount: 3`) |
| Jour courant | Cercle bleu à 30 % d'opacité |
| Jour sélectionné | Cercle bleu plein `#2E6AE6` |
| Jours hors mois | Masqués (`outsideDaysVisible: false`) |

#### Interactions

- **`onDaySelected`** : met à jour `_selectedDay` et `_focusedDay` via `setState`,
  ce qui rafraîchit la liste des événements en dessous.
- **`onPageChanged`** : met à jour `_focusedDay` sans `setState` (le calendrier
  gère lui-même le rendu du mois).

### Liste des événements du jour

`Expanded` sous le calendrier, séparé par un `Divider`.

| Cas | Affichage |
|---|---|
| Aucun événement | Texte centré "Aucune rencontre ce jour" |
| Un ou plusieurs | `ListView.builder` de `EventCard` |

Chaque `EventCard` reçoit :
- `event` : l'événement à afficher
- `isDark` : thème courant
- `currentUser` : utilisateur connecté (pour les actions d'inscription)
- `showParticipantCount: false` : masque le compteur de participants

---

## Services et widgets externes

| Élément | Rôle |
|---|---|
| `EventService` | Fournit le stream Realtime sur `events` |
| `EventCard` (`event_card_avec_inscription.dart`) | Carte événement avec bouton d'inscription |
| `table_calendar` | Widget calendrier mensuel interactif |

## Table Supabase

| Table | Opération |
|---|---|
| `events` | SELECT (stream Realtime via `EventService`) |

Aucune écriture n'est effectuée depuis cette page.

---

## Points d'attention

- Tous les événements sont chargés en mémoire sans pagination ni filtre de date.
  Si le volume d'événements devient important, un filtre par plage de dates
  côté Supabase serait préférable.
- La localisation `fr_FR` du calendrier nécessite l'initialisation de
  `initializeDateFormatting('fr_FR')` au démarrage de l'application
  (généralement dans `main.dart`).
- `markersMaxCount: 3` limite visuellement les points par jour — au-delà de
  3 événements le même jour, les marqueurs supplémentaires ne s'affichent pas.