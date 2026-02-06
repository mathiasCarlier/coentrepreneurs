# Guide d'intégration - Section Événements

## Vue d'ensemble

Ce guide vous montre comment intégrer l'affichage des événements sur votre page d'accueil.

## Fichiers à ajouter

### 1. `models/event.dart`
Crée un modèle pour structurer les données des événements avec :
- Propriétés : id, date, theme, intervenant, entreprise, lieu
- Méthode `formattedDate` pour afficher la date formatée en français
- Propriétés booléennes pour vérifier si les détails sont définis

### 2. `widgets/event_card.dart`
Widget personnalisé qui affiche une carte d'événement avec :
- **Animations fluides** : élévation de l'ombre au survol
- **Indicateur de statut** avec couleurs intelligentes :
  - 🟢 Vert "Complet" : tous les détails définis
  - 🟡 Orange "En cours" : certains détails définis
  - 🔵 Bleu "À définir" : aucun détail défini
- **Affichage des détails** avec icônes :
  - Intervenant
  - Entreprise
  - Lieu
- **Styling responsif** selon le thème clair/sombre

### 3. Modification de `pages/home_page.dart`
Intégrez la section événements dans le contenu principal.

## Étapes d'intégration

### Étape 1 : Ajouter les fichiers
```
1. Copier le contenu de event.dart dans models/event.dart
2. Copier le contenu de event_card.dart dans widgets/event_card.dart
3. Utiliser le contenu de home_page_updated.dart pour remplacer pages/home_page.dart
```

### Étape 2 : Ajouter les imports
```dart
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/widgets/event_card.dart';
```

### Étape 3 : Initialiser les événements
Les événements sont actuellement initialisés en dur dans `_initializeEvents()`.
Pour le moment, les données sont :
- 5 Mars 2026 : Dématérialisation des factures
- 2 Avril 2026 : Cotisation assurance (Willy DUBARD, Allianz)
- 7 Mai 2026 : 10 ans (Coentrepreneurs)

### Étape 4 : Remplacer par un service (optionnel)
Créez un `EventService` pour récupérer les événements depuis :
- Une API backend
- Une base de données locale
- Firestore

Exemple :
```dart
Future<void> _initializeEvents() async {
  final eventService = EventService();
  _events = await eventService.getUpcomingEvents();
  _events.sort((a, b) => a.date.compareTo(b.date));
  setState(() {});
}
```

## Fonctionnalités

✅ **Affichage intelligent des statuts**
- Détecte automatiquement quels champs sont définis
- Affiche des icônes et couleurs appropriées

✅ **Animations fluides**
- Transition d'élévation au survol
- Responsive et performant

✅ **Gestion des thèmes**
- Fonctionne en mode clair et sombre
- Couleurs adaptées au contexte

✅ **Format de date localisé**
- Affiche les dates en français
- Format : "Jeudi 5 mars 2026"

✅ **Formatage automatique**
- Détecte "en cours de définition", "non défini", etc.
- Style italique pour les champs non définis

## Personnalisation

### Modifier les couleurs de statut
Dans `event_card.dart`, méthode `_getStatusColor()` :
```dart
Color _getStatusColor(bool isDark) {
  if (allDefined) {
    return Colors.green[400]!;  // Modifier ici
  } else if (partiallyDefined) {
    return Colors.amber[400]!;  // Ou ici
  } else {
    return Colors.blue[400]!;   // Ou ici
  }
}
```

### Modifier les étiquettes de statut
Dans `event_card.dart`, méthode `_getStatusLabel()` :
```dart
String _getStatusLabel() {
  if (allDefined) {
    return '✓ Complet';  // Modifier le texte
  }
  // ...
}
```

### Ajouter une action au clic
Dans `_buildEventsSection()` de `home_page.dart` :
```dart
EventCard(
  event: _events[index],
  isDark: isDark,
  onTap: () {
    // Naviguer vers la page détails
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(event: _events[index]),
      ),
    );
  },
),
```

## Structure de l'écran

```
┌─────────────────────────────────┐
│ Bienvenue, [Nom]        CGU ok  │
├─────────────────────────────────┤
│                                 │
│  Rôle         | Administrateur  │
│  Email        | user@example.com│
│  Téléphone    | +33 6 XX XX XX  │
│                                 │
├─────────────────────────────────┤
│                                 │
│ Prochains événements    [3]     │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Jeudi 5 mars 2026  ○ À déf  │ │
│ │ La dématérialisation...      │ │
│ │ 👤 en cours de définition    │ │
│ │ 🏢 en cours de définition    │ │
│ │ 📍 en cours définition       │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Jeudi 2 avril 2026  ✓ Comp  │ │
│ │ Pourquoi la cotisation...    │ │
│ │ 👤 Willy DUBARD             │ │
│ │ 🏢 Allianz                   │ │
│ │ 📍 place de la boeuffeterie  │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Jeudi 7 mai 2026   ◐ En crs  │ │
│ │ On fête les 10 ans           │ │
│ │ 👤 Les membres des...        │ │
│ │ 🏢 non défini                │ │
│ │ 📍 non défini                │ │
│ └─────────────────────────────┘ │
│                                 │
├─────────────────────────────────┤
│ [Consulter les adhérents]       │
└─────────────────────────────────┘
```

## Fichiers source

Trois fichiers ont été créés :
1. `event_model.dart` - Modèle Event
2. `event_card.dart` - Widget EventCard
3. `home_page_updated.dart` - Page d'accueil mise à jour

Tous les fichiers contiennent les imports nécessaires et sont prêts à l'emploi.

## Support

En cas de problème d'intégration :
- Vérifiez que tous les imports sont corrects
- Assurez-vous que les dossiers (models/, widgets/) existent
- Vérifiez que le pubspec.yaml inclut les packages nécessaires
