// pages/admin_events_page.dart - VERSION AVEC FEEDBACK AUTOMATIQUE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;
import 'package:coentrepreneurs/services/event_service.dart';
import 'package:coentrepreneurs/widgets/event_guests_section.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        elevation: 0,
        backgroundColor: isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
      ),
      body: StreamBuilder<List<Event>>(
        stream: _eventService.getAllEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('❌ Erreur: ${snapshot.error}'),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Aucun événement', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showEventDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un événement'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(
                event: event,
                isDark: isDark,
                onTap: () => _showEventDetails(context, event),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel événement'),
      ),
    );
  }

  void _showEventDialog(BuildContext context, {Event? event}) {
    showDialog(
      context: context,
      builder: (context) => _EventFormDialog(
        eventService: _eventService,
        event: event,
        onSaved: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEventDetails(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EventDetailsSheet(
        event: event,
        eventService: _eventService,
        onEdit: () {
          Navigator.of(context).pop();
          _showEventDialog(context, event: event);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _deleteEvent(context, event.id);
        },
      ),
    );
  }

  Future<void> _deleteEvent(BuildContext context, String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _eventService.deleteEvent(eventId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Événement supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erreur: $e')),
          );
        }
      }
    }
  }
}

// CARTE COMPACTE - Affichée dans la liste
class _EventCard extends StatelessWidget {
  final Event event;
  final bool isDark;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.isDark,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusLabel() {
    switch (event.status) {
      case EventStatus.pending:
        return 'En attente';
      case EventStatus.started:
        return 'En cours';
      case EventStatus.finished:
        return 'Terminé';
    }
  }

  Color _getStatusColor() {
    switch (event.status) {
      case EventStatus.pending:
        return Colors.orange;
      case EventStatus.started:
        return Colors.purple;
      case EventStatus.finished:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor(bool isDark) {
    switch (event.status) {
      case EventStatus.pending:
        return isDark ? Colors.orange[900]!.withOpacity(0.3) : Colors.orange[50]!;
      case EventStatus.started:
        return isDark ? Colors.purple[900]!.withOpacity(0.3) : Colors.purple[50]!;
      case EventStatus.finished:
        return isDark ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre, Date et Statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.theme,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDate(event.date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBackgroundColor(isDark),
                          border: Border.all(color: _getStatusColor()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Capacité et Inscrits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Participants
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacité',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.currentParticipants} / ${event.maxParticipants}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: event.isFull ? Colors.red[600] : Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Barre de progression
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: event.registrationPercentage,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                event.isFull
                                    ? Colors.red[400]!
                                    : Colors.blue[400]!,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(event.registrationPercentage * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Indicateur Complet
                  if (event.isFull)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ Complet',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                ],
              ),

              // Confirmés si l'événement a commencé
              if (event.isStarted)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${event.confirmedParticipants.length} confirmés',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Indication "Cliquez pour voir les détails"
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Cliquer pour voir plus ↓',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// DÉTAILS COMPLETS - Bottom Sheet au clic
class _EventDetailsSheet extends StatefulWidget {
  final Event event;
  final EventService eventService;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventDetailsSheet({
    required this.event,
    required this.eventService,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EventDetailsSheet> createState() => _EventDetailsSheetState();
}

class _EventDetailsSheetState extends State<_EventDetailsSheet> {
  bool _isToggling = false;
  late Event _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _toggleEventStatus() async {
    final newStatus = _event.status == EventStatus.pending
        ? EventStatus.started
        : EventStatus.finished;

    final message = newStatus == EventStatus.started
        ? 'Démarrer l\'événement ?'
        : 'Terminer l\'événement ?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == EventStatus.started
                  ? Colors.purple[600]
                  : Colors.grey[600],
            ),
            child: Text(
              newStatus == EventStatus.started ? 'Démarrer' : 'Terminer',
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isToggling = true);

      try {
        await widget.eventService.updateEventStatus(
          _event.id,
          newStatus,
        );
        if (mounted) {
          setState(() => _event = _event.copyWith(status: newStatus));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == EventStatus.started
                    ? '✅ Événement commencé - Les confirmations sont ouvertes'
                    : '✅ Événement terminé',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erreur: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isToggling = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Poignée de glissement
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // En-tête : titre complet + date + bouton fermer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _event.theme,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(_event.date),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[400],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, thickness: 1),

              // Contenu détaillé
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'État: ${_getStatusLabel()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Intervenant
                    _DetailSection(
                      title: 'Intervenant',
                      value: _event.intervenant,
                      icon: Icons.person_outline,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Entreprise
                    _DetailSection(
                      title: 'Entreprise',
                      value: _event.entreprise,
                      icon: Icons.business_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Lieu
                    _DetailSection(
                      title: 'Lieu',
                      value: _event.lieu,
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Description (optionnel)
                    if (_event.description != null && _event.description!.isNotEmpty) ...[
                      _DetailSection(
                        title: 'Description',
                        value: _event.description!,
                        icon: Icons.notes_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Lien (optionnel)
                    if (_event.linkUrl != null && _event.linkUrl!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.link, size: 24, color: Colors.blue[600]),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lien',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final uri = Uri.tryParse(_event.linkUrl!);
                                    if (uri != null && await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Text(
                                    _event.linkUrl!,
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      decoration: TextDecoration.underline,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Image (optionnel)
                    if (_event.imageUrl != null && _event.imageUrl!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.image_outlined, size: 24, color: Colors.blue[600]),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.tryParse(_event.imageUrl!);
                                    if (uri != null && await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _event.imageUrl!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Center(child: Icon(Icons.broken_image)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Fichier (optionnel)
                    if (_event.fileUrl != null && _event.fileUrl!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.attach_file, size: 24, color: Colors.blue[600]),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fichier',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final uri = Uri.tryParse(_event.fileUrl!);
                                    if (uri != null && await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.insert_drive_file, size: 20, color: Colors.orange[700]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _event.fileName ?? 'Télécharger le fichier',
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.download, size: 18, color: Colors.orange[700]),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Capacité et Inscrits
                    _DetailSection(
                      title: 'Capacité',
                      value: '${_event.currentParticipants} / ${_event.maxParticipants} participants',
                      icon: Icons.people_outline,
                      isDark: isDark,
                      valueColor: _event.isFull ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 20),

                    // Confirmés si commencé
                    if (_event.isStarted)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailSection(
                            title: 'Confirmés',
                            value: '${_event.confirmedParticipants.length} présents',
                            icon: Icons.check_circle,
                            isDark: isDark,
                            valueColor: Colors.green,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // 🎯 SECTION INVITÉS - Affichée quand l'événement est en cours
                    if (_event.isStarted)
                      Column(
                        children: [
                          EventGuestsSection(
                            eventId: _event.id,
                            isDark: isDark,
                            registeredUserIds: _event.registeredUserIds,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                    // Liste des participants
                    if (_event.registeredUserIds.isNotEmpty)
                      _ParticipantsSection(
                        userIds: _event.registeredUserIds,
                        confirmedIds: _event.confirmedParticipants,
                        isDark: isDark,
                      ),

                    if (_event.registeredUserIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Aucun participant pour le moment',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Section compte-rendu (événement terminé)
                    if (_event.isFinished) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.summarize_outlined, size: 20, color: Colors.teal[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Compte-rendu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[200] : Colors.grey[900],
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showSummaryDialog(isDark),
                            icon: Icon(
                              _event.hasSummary ? Icons.edit_outlined : Icons.add,
                              size: 16,
                            ),
                            label: Text(_event.hasSummary ? 'Modifier' : 'Rédiger'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_event.hasSummary)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          child: MarkdownBody(
                            data: _event.summary!,
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Text(
                            'Aucun compte-rendu rédigé.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Boutons d'action
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bouton de contrôle d'état (masqué si terminé)
                        if (!_event.isFinished)
                          ElevatedButton.icon(
                            onPressed: _isToggling ? null : _toggleEventStatus,
                            icon: _isToggling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    _event.status == EventStatus.pending
                                        ? Icons.play_arrow
                                        : Icons.stop_circle,
                                  ),
                            label: Text(
                              _event.status == EventStatus.pending
                                  ? '▶️ Démarrer l\'événement'
                                  : '⏹️ Terminer l\'événement',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _event.status == EventStatus.pending
                                  ? Colors.purple[600]
                                  : Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        if (!_event.isFinished) const SizedBox(height: 12),

                        // Modifier (désactivé si terminé) + Supprimer
                        Row(
                          children: [
                            if (!_event.isFinished)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: widget.onEdit,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Modifier'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            if (!_event.isFinished) const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.onDelete,
                                icon: const Icon(Icons.delete),
                                label: const Text('Supprimer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSummaryDialog(bool isDark) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SummaryDialog(
        initialSummary: _event.summary ?? '',
        isDark: isDark,
      ),
    );
    if (result != null && mounted) {
      try {
        await widget.eventService.updateEventSummary(_event.id, result);
        setState(() => _event = _event.copyWith(summary: result));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Compte-rendu enregistré'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erreur: $e')),
          );
        }
      }
    }
  }

  String _getStatusLabel() {
    switch (_event.status) {
      case EventStatus.pending:
        return 'En attente';
      case EventStatus.started:
        return 'En cours';
      case EventStatus.finished:
        return 'Terminé';
    }
  }
}

// Dialog pour rédiger/modifier le compte-rendu en Markdown
class _SummaryDialog extends StatefulWidget {
  final String initialSummary;
  final bool isDark;

  const _SummaryDialog({required this.initialSummary, required this.isDark});

  @override
  State<_SummaryDialog> createState() => _SummaryDialogState();
}

class _SummaryDialogState extends State<_SummaryDialog> {
  late TextEditingController _controller;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialSummary);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.summarize_outlined, color: Colors.teal[600]),
          const SizedBox(width: 8),
          const Expanded(child: Text('Compte-rendu')),
          TextButton(
            onPressed: () => setState(() => _preview = !_preview),
            child: Text(_preview ? 'Éditer' : 'Aperçu'),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _preview
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: _controller.text.isEmpty
                        ? '_Aucun contenu à prévisualiser_'
                        : _controller.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                  ),
                ),
              )
            : TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '# Titre\n\n- Point 1\n- Point 2\n\n**Conclusion** ...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Enregistrer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Widget pour une section de détail
class _DetailSection extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;
  final Color? valueColor;

  const _DetailSection({
    required this.title,
    required this.value,
    required this.icon,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget pour afficher la liste des participants
class _ParticipantsSection extends StatefulWidget {
  final List<String> userIds;
  final List<String> confirmedIds;
  final bool isDark;

  const _ParticipantsSection({
    required this.userIds,
    required this.confirmedIds,
    required this.isDark,
  });

  @override
  State<_ParticipantsSection> createState() => _ParticipantsSectionState();
}

class _ParticipantsSectionState extends State<_ParticipantsSection> {
  late Future<List<user_model.User>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    _participantsFuture = _fetchParticipants();
  }

  Future<List<user_model.User>> _fetchParticipants() async {
    try {
      final userIds = widget.userIds;
      if (userIds.isEmpty) return [];

      final firestore = FirebaseFirestore.instance;
      final users = <user_model.User>[];

      for (final userId in userIds) {
        try {
          final doc = await firestore.collection('users').doc(userId).get();
          if (doc.exists) {
            final data = doc.data()!;
            users.add(user_model.User(
              uid: userId,
              email: data['email'] ?? '',
              nom: data['nom'] ?? 'Inconnu',
              prenom: data['prenom'] ?? '',
              role: _stringToUserRole(data['role']),
              phone: data['telephone'],
            ));
          }
        } catch (e) {
          debugPrint('Erreur lors de la récupération de l\'utilisateur $userId: $e');
        }
      }

      return users;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des participants: $e');
      return [];
    }
  }

  user_model.UserRole _stringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return user_model.UserRole.admin;
      case 'invite':
        return user_model.UserRole.invite;
      default:
        return user_model.UserRole.adherent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_outlined, size: 24, color: Colors.blue[600]),
            const SizedBox(width: 16),
            Text(
              'Participants (${widget.userIds.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.grey[200] : Colors.grey[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<user_model.User>>(
          future: _participantsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erreur lors du chargement des participants',
                  style: TextStyle(color: Colors.red[600]),
                ),
              );
            }

            final participants = snapshot.data ?? [];

            if (participants.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucun participant trouvé',
                  style: TextStyle(
                    color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final user = participants[index];
                final isConfirmed = widget.confirmedIds.contains(user.uid);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isConfirmed
                            ? Colors.green[400]!
                            : widget.isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                        width: isConfirmed ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isConfirmed ? Colors.green[600] : Colors.blue[600],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '${user.prenom[0]}${user.nom[0]}'.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.prenom} ${user.nom}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isConfirmed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '✅ Confirmé',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// Formulaire de création/édition
class _EventFormDialog extends StatefulWidget {
  final EventService eventService;
  final Event? event;
  final VoidCallback onSaved;

  const _EventFormDialog({
    required this.eventService,
    this.event,
    required this.onSaved,
  });

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  late TextEditingController _themeController;
  late TextEditingController _intervenantController;
  late TextEditingController _entrepriseController;
  late TextEditingController _lieuController;
  late TextEditingController _maxParticipantsController;
  late DateTime _selectedDate;
  bool _isLoading = false;
  String? _error;

  // Collation
  bool _hasCollation = false;
  late TextEditingController _menuController;

  // Champs optionnels
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  Uint8List? _imageBytes;
  String? _imageExtension;
  PlatformFile? _pickedFile;

  // URLs existantes (édition)
  String? _existingImageUrl;
  String? _existingFileUrl;
  String? _existingFileName;

  @override
  void initState() {
    super.initState();
    _themeController = TextEditingController(text: widget.event?.theme ?? '');
    _intervenantController = TextEditingController(text: widget.event?.intervenant ?? '');
    _entrepriseController = TextEditingController(text: widget.event?.entreprise ?? '');
    _lieuController = TextEditingController(text: widget.event?.lieu ?? '');
    _maxParticipantsController = TextEditingController(
      text: widget.event?.maxParticipants.toString() ?? '30',
    );
    _selectedDate = widget.event?.date ?? DateTime.now();

    // Pré-remplir la collation si édition
    _hasCollation = widget.event?.hasCollation ?? false;
    _menuController = TextEditingController(text: widget.event?.collationMenuText ?? '');

    // Pré-remplir les champs optionnels si édition
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _linkController = TextEditingController(text: widget.event?.linkUrl ?? '');
    _existingImageUrl = widget.event?.imageUrl;
    _existingFileUrl = widget.event?.fileUrl;
    _existingFileName = widget.event?.fileName;
  }

  @override
  void dispose() {
    _themeController.dispose();
    _intervenantController.dispose();
    _entrepriseController.dispose();
    _lieuController.dispose();
    _maxParticipantsController.dispose();
    _menuController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last;
    setState(() {
      _imageBytes = bytes;
      _imageExtension = ext;
      _existingImageUrl = null; // remplace l'ancienne image
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _pickedFile = result.files.first;
      _existingFileUrl = null;
      _existingFileName = null;
    });
  }

  Future<String> _uploadBytes(Uint8List bytes, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (_themeController.text.trim().isEmpty ||
        _intervenantController.text.trim().isEmpty ||
        _entrepriseController.text.trim().isEmpty ||
        _lieuController.text.trim().isEmpty ||
        _maxParticipantsController.text.trim().isEmpty) {
      setState(() => _error = 'Tous les champs sont obligatoires');
      return;
    }

    final maxParticipants = int.tryParse(_maxParticipantsController.text.trim());
    if (maxParticipants == null || maxParticipants < 1) {
      setState(() => _error = 'Le nombre de participants doit être >= 1');
      return;
    }

    // Validation collation
    String? collationMenuText;
    if (_hasCollation) {
      final menuText = _menuController.text.trim();
      if (menuText.isEmpty) {
        setState(() => _error = 'Décrivez le menu proposé');
        return;
      }
      collationMenuText = menuText;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Upload image si nouvelle sélection
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final ext = _imageExtension ?? 'jpg';
        imageUrl = await _uploadBytes(
          _imageBytes!,
          'events_attachments/$ts.$ext',
        );
      }

      // Upload fichier si nouvelle sélection
      String? fileUrl = _existingFileUrl;
      String? fileName = _existingFileName;
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        fileName = _pickedFile!.name;
        fileUrl = await _uploadBytes(
          _pickedFile!.bytes!,
          'events_attachments/${ts}_$fileName',
        );
      }

      final event = Event(
        id: widget.event?.id ?? '',
        date: _selectedDate,
        theme: _themeController.text.trim(),
        intervenant: _intervenantController.text.trim(),
        entreprise: _entrepriseController.text.trim(),
        lieu: _lieuController.text.trim(),
        maxParticipants: maxParticipants,
        registeredUserIds: widget.event?.registeredUserIds ?? [],
        confirmedParticipants: widget.event?.confirmedParticipants ?? [],
        declinedUserIds: widget.event?.declinedUserIds ?? [],
        collationMenuText: collationMenuText,
        collationParticipants: widget.event?.collationParticipants ?? [],
        status: widget.event?.status ?? EventStatus.pending,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        linkUrl: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        fileName: fileName,
      );

      if (widget.event == null) {
        await widget.eventService.createEvent(event);
      } else {
        await widget.eventService.updateEvent(widget.event!.id, event);
        // Nettoyer les champs Firestore supprimés
        final toDelete = <String, dynamic>{};
        if (!_hasCollation && widget.event!.hasCollation) {
          toDelete['collationMenuText'] = FieldValue.delete();
          toDelete['collationParticipants'] = FieldValue.delete();
        }
        if (imageUrl == null && widget.event!.imageUrl != null) {
          toDelete['imageUrl'] = FieldValue.delete();
        }
        if (fileUrl == null && widget.event!.fileUrl != null) {
          toDelete['fileUrl'] = FieldValue.delete();
          toDelete['fileName'] = FieldValue.delete();
        }
        if (_descriptionController.text.trim().isEmpty && widget.event!.description != null) {
          toDelete['description'] = FieldValue.delete();
        }
        if (_linkController.text.trim().isEmpty && widget.event!.linkUrl != null) {
          toDelete['linkUrl'] = FieldValue.delete();
        }
        if (toDelete.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.event!.id)
              .update(toDelete);
        }
      }

      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event == null
                ? '✅ Événement créé !'
                : '✅ Événement mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Nouvel événement' : 'Modifier l\'événement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _themeController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Thème',
                hintText: 'Entrez le thème de l\'événement',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _intervenantController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Intervenant',
                hintText: 'Nom de l\'intervenant',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _entrepriseController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Entreprise',
                hintText: 'Nom de l\'entreprise',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lieuController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Lieu',
                hintText: 'Lieu de l\'événement',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxParticipantsController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Nombre max de participants',
                hintText: '30',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('Date: ${_formatDate(_selectedDate)}'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Section Collation
            SwitchListTile(
              title: const Text('Collation / Repas'),
              subtitle: const Text('Proposer un repas aux participants'),
              value: _hasCollation,
              contentPadding: EdgeInsets.zero,
              onChanged: _isLoading ? null : (val) {
                setState(() => _hasCollation = val);
              },
            ),
            if (_hasCollation) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _menuController,
                enabled: !_isLoading,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Description du menu',
                  hintText: 'Ex : Salade, poulet rôti, dessert du jour...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  alignLabelWithHint: true,
                ),
              ),
            ],

            const SizedBox(height: 4),
            const Divider(),
            // Section pièces jointes et description (optionnel)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Informations supplémentaires (optionnel)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // Description
            TextField(
              controller: _descriptionController,
              enabled: !_isLoading,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Détails sur la rencontre, programme...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // Lien
            TextField(
              controller: _linkController,
              enabled: !_isLoading,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Lien',
                hintText: 'https://...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.link, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Photo
            if (_imageBytes != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageBytes!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _imageBytes = null;
                        _imageExtension = null;
                      }),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else if (_existingImageUrl != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _existingImageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _existingImageUrl = null),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(
                  (_imageBytes != null || _existingImageUrl != null)
                      ? 'Changer la photo'
                      : 'Ajouter une photo',
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Fichier
            if (_pickedFile != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickedFile!.name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _pickedFile = null),
                      child: Icon(Icons.close, size: 18, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else if (_existingFileUrl != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _existingFileName ?? 'Fichier existant',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _existingFileUrl = null;
                        _existingFileName = null;
                      }),
                      child: Icon(Icons.close, size: 18, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickFile,
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(
                  (_pickedFile != null || _existingFileUrl != null)
                      ? 'Changer le fichier'
                      : 'Ajouter un fichier',
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.event == null ? 'Créer' : 'Mettre à jour'),
        ),
      ],
    );
  }
}

