import 'package:flutter/material.dart';
import 'package:coentrepreneurs/models/event.dart';

/// Affiche le dialogue de sélection de collation pour un événement.
///
/// Retourne :
/// - `List<int>` des indices sélectionnés si l'utilisateur valide
/// - `[]` (liste vide) si l'utilisateur choisit "Ne pas participer"
/// - `null` si le dialogue est annulé (pas de changement)
Future<List<int>?> showCollationDialog(
  BuildContext context, {
  required Event event,
  required String currentUserId,
}) {
  return showDialog<List<int>>(
    context: context,
    builder: (context) => _CollationDialog(
      event: event,
      currentUserId: currentUserId,
    ),
  );
}

class _CollationDialog extends StatefulWidget {
  final Event event;
  final String currentUserId;

  const _CollationDialog({
    required this.event,
    required this.currentUserId,
  });

  @override
  State<_CollationDialog> createState() => _CollationDialogState();
}

class _CollationDialogState extends State<_CollationDialog> {
  late Set<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    // Pré-sélectionner les choix existants
    final existing = widget.event.collationParticipants[widget.currentUserId];
    _selectedIndices = existing != null ? Set<int>.from(existing) : {};
  }

  double get _total {
    if (widget.event.collationMenu == null) return 0;
    return _selectedIndices
        .where((i) => i >= 0 && i < widget.event.collationMenu!.length)
        .fold(0.0, (total, i) => total + widget.event.collationMenu![i].prix);
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.event.collationMenu!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.restaurant_menu, color: Colors.amber[700]),
          const SizedBox(width: 8),
          const Expanded(child: Text('Menu - Collation')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber[900]?.withValues(alpha: 0.2)
                    : Colors.amber[50],
                border: Border.all(
                  color: Colors.amber[400]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sélectionnez les plats que vous souhaitez commander.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.amber[300] : Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste des plats
            ...List.generate(menu.length, (index) {
              final item = menu[index];
              final isSelected = _selectedIndices.contains(index);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIndices.add(index);
                    } else {
                      _selectedIndices.remove(index);
                    }
                  });
                },
                title: Text(
                  item.nom,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${_formatPrice(item.prix)} €',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),

            // Total
            if (_selectedIndices.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_formatPrice(_total)} €',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(<int>[]),
          child: Text(
            'Ne pas participer',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedIndices.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedIndices.toList()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
