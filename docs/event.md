Résumé de `event.dart`

But: Modèle simple pour représenter un événement dans l'application.

Points clés

- `formattedDate` : méthode utilitaire pour afficher la date en français (jour, jour-num, mois, année).
- Flags `isDefinedIntervenant`, `isDefinedEntreprise`, `isDefinedLieu` : utilisés par l'UI
  pour déterminer si afficher la valeur ou un état «en cours de définition».

Conseils

- Centraliser la localisation des dates si l'app doit supporter plusieurs langues.
- Tests : vérifier `formattedDate` sur plusieurs dates (fin/ début d'année, jours de la semaine).
