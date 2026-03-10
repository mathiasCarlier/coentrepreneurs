import 'package:flutter/material.dart';
import 'package:coentrepreneurs/models/badge_model.dart';
import 'package:coentrepreneurs/services/badge_service.dart';

/// Affiche la section Badges en chargeant les données depuis Supabase.
/// [userData] doit contenir les champs de la table `users`.
class BadgesSection extends StatefulWidget {
  final Map<String, dynamic> userData;

  const BadgesSection({super.key, required this.userData});

  @override
  State<BadgesSection> createState() => _BadgesSectionState();
}

class _BadgesSectionState extends State<BadgesSection> {
  late Future<BadgeData> _future;

  @override
  void initState() {
    super.initState();
    _future = BadgeService.loadBadges(widget.userData);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber[900]?.withValues(alpha: 0.12)
            : Colors.amber[50],
        border: Border.all(
          color: isDark
              ? Colors.amber[700]!.withValues(alpha: 0.4)
              : Colors.amber[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech, color: Colors.amber[700], size: 22),
              const SizedBox(width: 8),
              Text(
                'Badges',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<BadgeData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final earned = snapshot.data?.earned ?? [];

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: BadgeType.values.map((type) {
                  final info = kBadges[type]!;
                  final isEarned = earned.contains(type);
                  return _BadgeChip(info: info, earned: isEarned, isDark: isDark);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final BadgeInfo info;
  final bool earned;
  final bool isDark;

  const _BadgeChip({
    required this.info,
    required this.earned,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = earned ? info.color : (isDark ? Colors.grey[700]! : Colors.grey[400]!);

    return Tooltip(
      message: info.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: earned
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? Colors.grey[850] : Colors.grey[200]),
          border: Border.all(
            color: earned ? color.withValues(alpha: 0.6) : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              earned ? info.icon : Icons.lock_outline,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              info.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: earned ? FontWeight.bold : FontWeight.normal,
                color: earned
                    ? (isDark ? color.withValues(alpha: 0.9) : color)
                    : (isDark ? Colors.grey[500] : Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
