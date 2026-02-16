// widgets/event_card.dart - VERSION AVEC CONFIRMATION DE PRÉSENCE
import 'package:flutter/material.dart';
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/models/user.dart';
import 'package:coentrepreneurs/services/registration_service.dart';
import 'package:coentrepreneurs/services/location_service.dart';
import 'package:coentrepreneurs/services/event_service.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final bool isDark;
  final User? currentUser;
  final bool showParticipantCount;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.isDark,
    this.currentUser,
    this.showParticipantCount = true,
    this.onTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevation;
  final RegistrationService _registrationService = RegistrationService();
  final EventService _eventService = EventService();
  late bool _isUserRegistered;
  bool _isLoading = false;

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
    _isUserRegistered = widget.currentUser != null 
        ? widget.event.isUserRegistered(widget.currentUser!.uid)
        : false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // État 2: Inscrit mais pas confirmé
  bool get _isUserInscribed {
    return widget.currentUser != null
        ? widget.event.isUserRegistered(widget.currentUser!.uid)
        : false;
  }

  // État 3: Confirmé
  bool get _isUserConfirmed {
    return widget.currentUser != null
        ? widget.event.isUserConfirmed(widget.currentUser!.uid)
        : false;
  }

  Future<void> _toggleRegistration() async {
    if (widget.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour vous inscrire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Empêcher la désinscription si confirmé
    if (_isUserInscribed && _isUserConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vous ne pouvez pas annuler après avoir confirmé votre présence'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isUserInscribed) {
        // Désinscrire (seulement si pas confirmé)
        await _registrationService.unregisterUserFromEvent(
          widget.event.id,
          widget.currentUser!.uid,
        );
        if (mounted) {
          setState(() => _isUserRegistered = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Vous avez annulé votre inscription'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // Vérifier la capacité
        if (widget.event.isFull) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Cet événement est complet'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Inscrire (État 2: Inscrit, pas encore confirmé)
        await _registrationService.registerUserToEvent(
          widget.event.id,
          widget.currentUser!.uid,
        );
        if (mounted) {
          setState(() => _isUserRegistered = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Inscription confirmée!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openLocation() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ouverture de Google Maps...'),
          duration: Duration(seconds: 1),
        ),
      );
      await LocationService.openMaps(widget.event.lieu);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: Impossible d\'ouvrir Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                child: _isUserConfirmed
                    ? _buildConfirmedView()  // État 3: Confirmé
                    : _isUserInscribed
                        ? _buildInscribedView()  // État 2: Inscrit
                        : _buildUnregisteredView(),  // État 1: Non inscrit
              ),
            ),
          );
        },
      ),
    );
  }

  // ========================================
  // ÉTAT 1: NON INSCRIT (Vue complète)
  // ========================================
  Widget _buildUnregisteredView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
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
        _buildLocationRow(
          context,
          widget.event.lieu,
          isDefined: widget.event.isDefinedLieu,
        ),

        const SizedBox(height: 16),

        // Bouton S'inscrire
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isLoading || (widget.event.isFull && !_isUserInscribed)
                ? null
                : _toggleRegistration,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'En cours...' : 'S\'inscrire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // ÉTAT 2: INSCRIT MAIS PAS CONFIRMÉ
  // ========================================
  Widget _buildInscribedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête compact avec badge "En attente"
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
            const SizedBox(width: 12),
            // Badge "En attente" (orange)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[900]?.withOpacity(0.3),
                border: Border.all(
                  color: Colors.orange[400]!,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.orange[400]),
                  const SizedBox(width: 6),
                  Text(
                    'En attente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[300],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lieu
        GestureDetector(
          onTap: widget.event.isDefinedLieu ? _openLocation : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: widget.event.isDefinedLieu ? Colors.blue[400] : Colors.orange[300],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lieu',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.event.lieu,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.event.isDefinedLieu
                            ? (widget.isDark ? Colors.grey[100] : Colors.grey[900])
                            : Colors.orange[300],
                        fontWeight: widget.event.isDefinedLieu ? FontWeight.w500 : FontWeight.w400,
                        fontStyle: widget.event.isDefinedLieu ? FontStyle.normal : FontStyle.italic,
                        decoration: widget.event.isDefinedLieu ? TextDecoration.underline : null,
                        decorationColor: Colors.blue[400],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.event.isDefinedLieu)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '🔗 Cliquer pour ouvrir Maps',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue[400],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bouton Annuler l'inscription
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _toggleRegistration,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Annuler l\'inscription'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[600]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // État 3: Confirmé
  // ========================================
  Widget _buildConfirmedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête compact avec badge "Présent ✅"
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
            const SizedBox(width: 12),
            // Badge "Présent ✅" (vert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[900]?.withOpacity(0.3),
                border: Border.all(
                  color: Colors.green[400]!,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Présent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[300],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lieu
        GestureDetector(
          onTap: widget.event.isDefinedLieu ? _openLocation : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: widget.event.isDefinedLieu ? Colors.blue[400] : Colors.orange[300],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lieu',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.event.lieu,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.event.isDefinedLieu
                            ? (widget.isDark ? Colors.grey[100] : Colors.grey[900])
                            : Colors.orange[300],
                        fontWeight: widget.event.isDefinedLieu ? FontWeight.w500 : FontWeight.w400,
                        fontStyle: widget.event.isDefinedLieu ? FontStyle.normal : FontStyle.italic,
                        decoration: widget.event.isDefinedLieu ? TextDecoration.underline : null,
                        decorationColor: Colors.blue[400],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.event.isDefinedLieu)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '🔗 Cliquer pour ouvrir Maps',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.blue[400],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // WIDGETS HELPERS
  // ========================================

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
          color: isDefined ? Colors.blue[400] : Colors.orange[300],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
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

  Widget _buildLocationRow(
    BuildContext context,
    String value, {
    required bool isDefined,
  }) {
    return GestureDetector(
      onTap: isDefined ? _openLocation : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: isDefined ? Colors.blue[400] : Colors.orange[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lieu',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
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
                    decoration: isDefined ? TextDecoration.underline : null,
                    decorationColor: Colors.blue[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDefined)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '🔗 Cliquer pour ouvrir Maps',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue[400],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      setState(() {});
    }
    if (oldWidget.currentUser?.uid != widget.currentUser?.uid ||
        oldWidget.event.id != widget.event.id) {
      _isUserRegistered = widget.currentUser != null 
          ? widget.event.isUserRegistered(widget.currentUser!.uid)
          : false;
    }
  }
}