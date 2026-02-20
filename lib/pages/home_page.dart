// pages/home_page.dart - VERSION MISE À JOUR AVEC FILTRAGE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:coentrepreneurs/services/auth_service.dart';
import 'package:coentrepreneurs/services/cgu_service.dart';
import 'package:coentrepreneurs/services/event_service.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/widgets/cgu_acceptance_dialog.dart';
import 'package:coentrepreneurs/widgets/event_card_avec_inscription.dart';
import 'package:coentrepreneurs/pages/settings_page.dart'; 
import 'package:coentrepreneurs/pages/messages_page.dart';
import 'package:coentrepreneurs/pages/admin_events_page.dart'; 
import 'package:coentrepreneurs/pages/faq_page.dart'; 
import 'package:coentrepreneurs/pages/directory_page_dynamic.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CGUService _cguService = CGUService();
  final EventService _eventService = EventService();
  bool _cguCheckCompleted = false;
  bool _userAcceptedCGU = false;

  @override
  void initState() {
    super.initState();
    _checkAndHandleCGU();
    _initializeDefaultEvents();
  }

  Future<void> _initializeDefaultEvents() async {
    await _eventService.initializeDefaultEvents();
  }

  Future<void> _checkAndHandleCGU() async {
    final auth = context.read<AuthService>();
    final user = await auth.currentUser;

    if (user != null) {
      final hasAccepted = await _cguService.hasUserAcceptedCGU(user.uid);

      setState(() {
        _userAcceptedCGU = hasAccepted;
        _cguCheckCompleted = true;
      });

      if (!hasAccepted && mounted) {
        _showCGUDialog(user.uid);
      }
    }
  }

  void _showCGUDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CGUAcceptanceDialog(
        userId: userId,
        onAccepted: () async {
          try {
            await _cguService.acceptCGU(userId);
            if (mounted) {
              setState(() => _userAcceptedCGU = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conditions acceptées avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
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
          }
        },
      ),
    ).then((accepted) {
      if (accepted != true) {
        _handleCGURejection();
      }
    });
  }

  void _handleCGURejection() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Accès refusé'),
        content: const Text(
          'Vous devez accepter les conditions d\'utilisation pour accéder à l\'application. '
          'Vous allez être déconnecté.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    await auth.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        // MODIFICATION 1 : Remplacer le titre par une icône maison
        title: const Icon(Icons.home, size: 28),
        elevation: 0,
        backgroundColor: isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
        actions: [
          // NOUVEAU : Bouton FAQ
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FAQPage(),
                ),
              );
            },
            icon: const Icon(Icons.help_outline, size: 24),
            tooltip: 'FAQ',
          ),
          // Bouton paramètres existant
          IconButton(
            onPressed: () {
              final auth = context.read<AuthService>();
              final userStream = auth.authStateChanges;
              userStream.first.then((user) {
                if (user != null && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(user: user),
                    ),
                  );
                }
              });
            },
            icon: const Icon(Icons.settings, size: 24),
            tooltip: 'Paramètres',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 24),
            tooltip: 'Déconnexion',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<user_model.User?>(
        stream: auth.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return Center(
              child: Text(
                'Non connecté',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          if (!_cguCheckCompleted) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_userAcceptedCGU) {
            return _buildAccessDeniedScreen(context, user);
          }

          return _buildMainContent(context, user);
        },
      ),
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context, user_model.User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.1),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.orange[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Accès limité',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Vous devez accepter les conditions d\'utilisation pour accéder à l\'application.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showCGUDialog(user.uid);
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text('Lire et accepter les conditions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, user_model.User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context, user, isDark),
            const SizedBox(height: 32),
            _buildContactSection(context, user, isDark),
            const SizedBox(height: 32),
            _buildEventsSection(context, user, isDark),
            const SizedBox(height: 32),
            _buildActionsSection(context, user, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, user_model.User user, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue, ${user.prenom}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.purple[700] : Colors.purple[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getRoleLabel(user.role),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isDark ? Colors.white : Colors.purple[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context, user_model.User user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.blue[900]!.withOpacity(0.3),
                  Colors.purple[900]!.withOpacity(0.3),
                ]
              : [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.question_answer,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Une question ?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Idées, aides, problèmes... Nous sommes là pour vous',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.lightbulb_outline,
                  label: 'Une idée',
                  color: Colors.green,
                  onPressed: () =>
                      _showMessageDialog(context, user, 'Nouvelle idée'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactButton(
                  icon: Icons.help_outline,
                  label: 'Besoin d\'aide',
                  color: Colors.green,
                  onPressed: () =>
                      _showMessageDialog(context, user, 'Demande d\'aide'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Un problème',
                  color: Colors.green,
                  onPressed: () =>
                      _showMessageDialog(context, user, 'Signalement de problème'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactButton(
                  icon: Icons.star_outline,
                  label: 'Bon plan',
                  color: Colors.green,
                  onPressed: () =>
                      _showMessageDialog(context, user, 'Bon plan à proposer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context, user_model.User user, String category) {
    showDialog(
      context: context,
      builder: (context) => _MessageFormDialog(
        user: user,
        category: category,
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, user_model.User user, bool isDark) {
    return Column(
      children: [
        if (user.role == user_model.UserRole.admin)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AdminEventsPage()),
                );
              },
              icon: const Icon(Icons.event),
              label: const Text('Gérer les événements'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (user.role == user_model.UserRole.admin) const SizedBox(height: 12),

        if (user.role == user_model.UserRole.admin)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MessagesPage()),
                );
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text('Consulter les messages'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (user.role == user_model.UserRole.admin) const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DirectoryPageDynamic()),
              );
            },
            icon: const Icon(Icons.people_outline),
            label: const Text('Consulter les adhérents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 95, 5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleLabel(user_model.UserRole role) {
    switch (role) {
      case user_model.UserRole.admin:
        return 'Administrateur';
      case user_model.UserRole.adherent:
        return 'Adhérent';
      case user_model.UserRole.invite:
        return 'Invité';
    }
  }

  Widget _buildEventsSection(BuildContext context, user_model.User user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Événements à venir',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Event>>(
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

            final allEvents = snapshot.data ?? [];

            // Filtrer les événements futurs (à partir d'aujourd'hui)
            final today = DateTime.now();
            final todayStart = DateTime(today.year, today.month, today.day);
            
            final upcomingEvents = allEvents
                .where((event) {
                  // Créer une date sans l'heure pour comparer uniquement la date
                  final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
                  return eventDate.isAtSameMomentAs(todayStart) || eventDate.isAfter(todayStart);
                })
                .take(2) // Prendre seulement les 2 prochains
                .toList();

            if (upcomingEvents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucun événement prévu pour le moment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                return EventCard(
                  event: upcomingEvents[index],
                  isDark: isDark,
                  currentUser: user,
                  showParticipantCount: false, // ← CACHE LE NOMBRE DE PARTICIPANTS
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Détails: ${upcomingEvents[index].theme}')),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}

/// Formulaire simple pour écrire un message (stocké dans Firestore)
class _MessageFormDialog extends StatefulWidget {
  final user_model.User user;
  final String category;

  const _MessageFormDialog({
    required this.user,
    required this.category,
  });

  @override
  State<_MessageFormDialog> createState() => _MessageFormDialogState();
}

class _MessageFormDialogState extends State<_MessageFormDialog> {
  late TextEditingController _messageController;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    if (_messageController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer un message');
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      // Stocker le message dans Firestore
      await FirebaseFirestore.instance.collection('messages').add({
        'userId': widget.user.uid,
        'userName': '${widget.user.prenom} ${widget.user.nom}',
        'userEmail': widget.user.email,
        'userRole': widget.user.role.toString(),
        'category': widget.category,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message enregistré avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() => _error = 'Erreur: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(widget.category),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Votre message:',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 8,
              minLines: 6,
              enabled: !_isSending,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Écrivez votre message ici...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
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
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _submitMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }
}