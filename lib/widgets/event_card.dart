// widgets/event_card.dart
import 'package:flutter/material.dart';
import 'package:coentrepreneurs/models/event.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final bool isDark;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.isDark,
    this.onTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _elevation = Tween<double>(begin: 2, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _elevation,
        builder: (context, child) {
          return Card(
            elevation: _elevation.value,
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.isDark 
                  ? Colors.grey[800]!.withOpacity(0.5)
                  : Colors.grey[200]!,
                width: 1,
              ),
            ),
            color: widget.isDark 
              ? Colors.grey[900]?.withOpacity(0.6)
              : Colors.white,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date et indicateur de statut
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.event.formattedDate,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.blue[400],
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.event.theme,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Détails
                    _buildDetailRow(
                      context,
                      Icons.person_outline,
                      'Intervenant',
                      widget.event.intervenant,
                      isDefined: widget.event.isDefinedIntervenant,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      Icons.business_outlined,
                      'Entreprise',
                      widget.event.entreprise,
                      isDefined: widget.event.isDefinedEntreprise,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      Icons.location_on_outlined,
                      'Lieu',
                      widget.event.lieu,
                      isDefined: widget.event.isDefinedLieu,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    required bool isDefined,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDefined
            ? Colors.blue[400]
            : Colors.orange[300],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: widget.isDark 
                    ? Colors.grey[500]
                    : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDefined
                    ? (widget.isDark ? Colors.grey[100] : Colors.grey[900])
                    : Colors.orange[300],
                  fontWeight: isDefined ? FontWeight.w500 : FontWeight.w400,
                  fontStyle: isDefined ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      setState(() {});
    }
  }
}
