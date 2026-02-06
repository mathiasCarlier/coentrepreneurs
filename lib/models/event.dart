// models/event.dart
class Event {
  final String id;
  final DateTime date;
  final String theme;
  final String intervenant;
  final String entreprise;
  final String lieu;

  Event({
    required this.id,
    required this.date,
    required this.theme,
    required this.intervenant,
    required this.entreprise,
    required this.lieu,
  });

  // Méthode pour formater la date
  String get formattedDate {
    const monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    const dayNames = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];

    final dayName = dayNames[date.weekday - 1];
    final monthName = monthNames[date.month - 1];

    return '$dayName ${date.day} ${monthName.toLowerCase()} ${date.year}';
  }

  // Flags utilitaires utilisés par l'UI pour indiquer si un champ est vraiment
  // renseigné ou si c'est une valeur placeholder comme "en cours de définition".
  bool get isDefinedIntervenant => intervenant.toLowerCase() != 'en cours de définition';
  bool get isDefinedEntreprise => entreprise.toLowerCase() != 'en cours de définition' && entreprise.toLowerCase() != 'non défini';
  bool get isDefinedLieu => lieu.toLowerCase() != 'en cours définition' && lieu.toLowerCase() != 'non défini';
}
