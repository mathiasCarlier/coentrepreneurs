// pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:coentrepreneurs/services/auth_service.dart';
import 'package:coentrepreneurs/services/cgu_service.dart';
import 'package:coentrepreneurs/models/user.dart';
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/widgets/cgu_acceptance_dialog.dart';
import 'package:coentrepreneurs/widgets/event_card.dart';
import 'package:coentrepreneurs/pages/directory_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CGUService _cguService = CGUService();
  bool _cguCheckCompleted = false;
  bool _userAcceptedCGU = false;
  late List<Event> _events;

  @override
  void initState() {
    super.initState();
    _initializeEvents();
    _checkAndHandleCGU();
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

  // NOTE: _checkAndHandleCGU
  // - Récupère l'utilisateur courant via AuthService (peut effectuer un accès réseau)
  // - Vérifie en Firestore si l'utilisateur a accepté la version actuelle des CGU
  // - Met à jour l'état local (_cguCheckCompleted / _userAcceptedCGU) puis
  //   affiche la boîte de dialogue d'acceptation si nécessaire.
  // Important: cette méthode est appelée depuis initState; elle doit gérer
  // correctement `mounted` pour éviter les setState sur widget démonté.

  void _showCGUDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CGUAcceptanceDialog(
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
        // L'utilisateur a refusé les conditions
        _handleCGURejection();
      }
    });
  }

  // NOTE: _showCGUDialog
  // - Affiche le `CGUAcceptanceDialog` et attend l'action de l'utilisateur.
  // - En cas d'acceptation, appelle le service pour enregistrer l'acceptation
  //   et met à jour l'UI (SnackBar + état local).
  // - `.then((accepted) { ... })` gère explicitement le cas où l'utilisateur
  //   ferme ou refuse la dialog; cela déclenche une déconnexion contrôlée.

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

  void _initializeEvents() {
    _events = [
      Event(
        id: '1',
        date: DateTime(2026, 3, 5),
        theme:
            'La dématérialisation des factures achats/ventes. Comment faire ?',
        intervenant: 'en cours de définition',
        entreprise: 'en cours de définition',
        lieu: 'en cours définition',
      ),
      Event(
        id: '2',
        date: DateTime(2026, 4, 2),
        theme: 'Pourquoi la cotisation de l\'assurance augmente ?',
        intervenant: 'Willy DUBARD',
        entreprise: 'Allianz',
        lieu: 'place de la boeuffeterie 86200 LOUDUN',
      ),
      Event(
        id: '3',
        date: DateTime(2026, 5, 7),
        theme: 'On fête les 10 ans',
        intervenant: 'Les membres des coentrepreneurs',
        entreprise: 'non défini',
        lieu: 'en cours de définition',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Déconnexion'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<User?>(
        // Le StreamBuilder écoute `auth.authStateChanges` provenant de
        // `AuthService`. Ce stream émet un `User?` à chaque changement
        // d'état d'authentification (login/logout). Le builder doit gérer
        // correctement les états `waiting` / `active` et tenir compte
        // des vérifications asynchrones des CGU effectuées dans initState.
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

          // Attendre la vérification des CGU
          if (!_cguCheckCompleted) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si l'utilisateur n'a pas accepté les CGU, afficher un message
          if (!_userAcceptedCGU) {
            return _buildAccessDeniedScreen(context, user);
          }

          // Contenu principal si CGU acceptées
          return _buildMainContent(context, user);
        },
      ),
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context, User user) {
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

  Widget _buildMainContent(BuildContext context, User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec bienvenue
            _buildWelcomeSection(context, user, isDark),
            const SizedBox(height: 32),

            // Section infos utilisateur
            _buildUserInfoSection(context, user, isDark),
            const SizedBox(height: 32),

            // NOUVELLE SECTION: Contact/Question
            _buildContactSection(context, user, isDark),
            const SizedBox(height: 32),

            // Section événements
            _buildEventsSection(context, isDark),
            const SizedBox(height: 32),

            // Section actions
            _buildActionsSection(context, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, User user, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue,',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.nomComplet,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green[900]?.withOpacity(0.3),
            border: Border.all(color: Colors.green[400]!, width: 1.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
              const SizedBox(width: 6),
              Text(
                'CGU ok',
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
    );
  }

  Widget _buildUserInfoSection(BuildContext context, User user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]?.withOpacity(0.5) : Colors.grey[100],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Rôle',
            value: _getRoleLabel(user.role),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Email', value: user.email, isDark: isDark),
          if (user.phone.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoRow(label: 'Téléphone', value: user.phone, isDark: isDark),
          ],
        ],
      ),
    );
  }

  // NOUVELLE MÉTHODE: Section Contact
  Widget _buildContactSection(BuildContext context, User user, bool isDark) {
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
                  color: Colors.orange,
                  onPressed: () => _sendEmail(context, user, 'Nouvelle idée'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactButton(
                  icon: Icons.help_outline,
                  label: 'Besoin d\'aide',
                  color: Colors.blue,
                  onPressed: () => _sendEmail(context, user, 'Demande d\'aide'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _ContactButton(
              icon: Icons.report_problem_outlined,
              label: 'Signaler un problème',
              color: Colors.red,
              onPressed: () =>
                  _sendEmail(context, user, 'Signalement de problème'),
            ),
          ),
        ],
      ),
    );
  }

  // NOUVELLE MÉTHODE: Envoi d'email
  Future<void> _sendEmail(
    BuildContext context,
    User user,
    String subject,
  ) async {
    // Remplacez cette adresse par l'email de destination souhaité
    const String destinationEmail = 'boris.lejude@gmail.com';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: destinationEmail,
      queryParameters: {
        'subject': '[$subject] - ${user.nomComplet}',
        'body':
            'Bonjour,\n\n'
            '[Écrivez votre message ici]\n\n'
            '---\n'
            'Envoyé par: ${user.nomComplet}\n'
            'Email: ${user.email}\n'
            'Rôle: ${_getRoleLabel(user.role)}',
      },
    );

    try {
      // Sur web, on lance directement sans vérification
      if (kIsWeb) {
        await launchUrl(emailUri);
      } else {
        // Sur mobile/desktop, on vérifie d'abord
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Impossible d\'ouvrir l\'application email'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de l\'email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionsSection(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          // Redirection vers la page interne de l'annuaire au lieu de l'URL externe
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DirectoryPage()),
          );
        },
        icon: const Icon(Icons.people_outline),
        label: const Text('Consulter les adhérents'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: const Color.fromARGB(255, 1, 73, 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.adherent:
        return 'Adhérent';
      case UserRole.invite:
        return 'Invité';
    }
  }

  Widget _buildEventsSection(BuildContext context, bool isDark) {
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _events.length,
          itemBuilder: (context, index) {
            return EventCard(
              event: _events[index],
              isDark: isDark,
              onTap: () {
                // Vous pouvez ajouter la navigation vers les détails de l'événement
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Détails: ${_events[index].theme}')),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// Widget pour les boutons de contact
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[100] : Colors.grey[900],
            ),
          ),
        ),
      ],
    );
  }
}
