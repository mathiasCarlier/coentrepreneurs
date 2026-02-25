import 'package:flutter/material.dart';
import 'package:coentrepreneurs/models/event.dart';

/// Affiche le dialogue de participation au repas pour un événement.
///
/// Retourne :
/// - `true` si l'utilisateur souhaite participer au repas
/// - `false` si l'utilisateur ne souhaite pas participer
/// - `null` si le dialogue est annulé (pas de changement)
Future<bool?> showCollationDialog(
  BuildContext context, {
  required Event event,
  required String currentUserId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _CollationDialog(
      event: event,
      currentUserId: currentUserId,
    ),
  );
}

class _CollationDialog extends StatelessWidget {
  final Event event;
  final String currentUserId;

  const _CollationDialog({
    required this.event,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alreadyParticipating = event.hasUserChosenCollation(currentUserId);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.restaurant_menu, color: Colors.amber[700]),
          const SizedBox(width: 8),
          const Expanded(child: Text('Repas / Collation')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.amber[900]?.withValues(alpha: 0.2)
                  : Colors.amber[50],
              border: Border.all(color: Colors.amber[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Menu proposé',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber[300] : Colors.amber[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.collationMenuText ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.amber[100] : Colors.amber[900],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            alreadyParticipating
                ? 'Vous participez actuellement au repas. Souhaitez-vous modifier votre réponse ?'
                : 'Souhaitez-vous participer au repas ?',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
          child: const Text('Non merci'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Oui, je participe'),
        ),
      ],
    );
  }
}
