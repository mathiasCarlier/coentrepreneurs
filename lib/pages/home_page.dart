// pages/home_page.dart - VERSION AVEC NOTIFICATIONS
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badges/badges.dart' as badges;

import 'package:coentrepreneurs/services/auth_service.dart';
import 'package:coentrepreneurs/services/cgu_service.dart';
import 'package:coentrepreneurs/services/event_service.dart';
import 'package:coentrepreneurs/services/storage_service.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/widgets/cgu_acceptance_dialog.dart';
import 'package:coentrepreneurs/widgets/event_card_avec_inscription.dart';
import 'package:coentrepreneurs/widgets/feedback_prompt.dart';
import 'package:coentrepreneurs/pages/settings_page.dart';
import 'package:coentrepreneurs/pages/messages_page.dart';
import 'package:coentrepreneurs/pages/admin_events_page.dart';
import 'package:coentrepreneurs/pages/faq_page.dart';
import 'package:coentrepreneurs/pages/directory_page_dynamic.dart';
import 'package:coentrepreneurs/pages/notifications_page.dart';
import 'package:coentrepreneurs/pages/all_events_page.dart';
import 'package:coentrepreneurs/pages/admin_users_page.dart';
import 'package:coentrepreneurs/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CGUService _cguService = CGUService();
  final EventService _eventService = EventService();
  final NotificationService _notificationService = NotificationService();
  bool _cguCheckCompleted = false;
  bool _userAcceptedCGU = false;

  // Supabase realtime subscription for blocked status
  RealtimeChannel? _blockedChannel;
  String? _listenedUid;

  // Stream controller for approval status polling
  StreamController<Map<String, dynamic>?>? _approvalStreamController;
  Timer? _approvalPollingTimer;
  Timer? _notificationPollingTimer;
  StreamController<int>? _notificationStreamController;

  // Cached streams — évite de recréer un stream (et un timer) à chaque rebuild
  Stream<user_model.User?>? _authStream;
  Stream<int>? _notificationCountStream;
  Stream<Map<String, dynamic>?>? _approvalStream;
  String? _cachedApprovalUid;
  Stream<List<Event>>? _eventsStream;

  @override
  void initState() {
    super.initState();
    _authStream = context.read<AuthService>().authStateChanges;
    _checkAndHandleCGU();
    _initializeDefaultEvents();
    _initPushNotifications();
  }

  Future<void> _initPushNotifications() async {
    if (!kIsWeb) return;
    final auth = context.read<AuthService>(); // capture avant tout await
    final user = await auth.currentUser;
    if (user == null) return;

    // N'initialiser les push que pour les utilisateurs approuvés
    final data = await Supabase.instance.client
        .from('users')
        .select('approval_status')
        .eq('id', user.uid)
        .maybeSingle();
    if (data?['approval_status'] != 'approved') return;

    await _notificationService.initialize(user.uid);
  }

  @override
  void dispose() {
    _blockedChannel?.unsubscribe();
    _approvalPollingTimer?.cancel();
    _approvalStreamController?.close();
    _notificationPollingTimer?.cancel();
    _notificationStreamController?.close();
    super.dispose();
  }

  /// Démarre un listener Supabase Realtime pour détecter un blocage admin.
  void _startBlockedListener(String uid) {
    if (_listenedUid == uid) return;
    _blockedChannel?.unsubscribe();
    _listenedUid = uid;

    _blockedChannel = Supabase.instance.client
        .channel('blocked_user_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: uid,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord['blocked'] == true && mounted) {
              _blockedChannel?.unsubscribe();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Votre accès a été bloqué par un administrateur.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
              Future.delayed(const Duration(seconds: 1), _logout);
            }
          },
        )
        .subscribe();
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
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CGUAcceptanceDialog(
        userId: userId,
        onAccepted: () async {
          try {
            await _cguService.acceptCGU(userId);
            // Ne remettre en "pending" que si le compte n'est pas déjà approuvé
            // (évite d'écraser "approved" en cas d'erreur réseau sur le check CGU)
            final currentData = await Supabase.instance.client
                .from('users')
                .select('approval_status')
                .eq('id', userId)
                .maybeSingle();
            if (currentData?['approval_status'] != 'approved') {
              await Supabase.instance.client
                  .from('users')
                  .update({'approval_status': 'pending'})
                  .eq('id', userId);
            }
            if (mounted) {
              setState(() => _userAcceptedCGU = true);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'Votre demande d\'adhésion est en attente de validation par un administrateur.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
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
            child: Text(
              'Déconnexion',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>(); // capture avant tout await
    if (kIsWeb) {
      await _notificationService.deleteSubscription();
    }
    await auth.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  /// Returns a stream that emits the user's approval status map from Supabase
  /// by polling every 10 seconds.
  Stream<Map<String, dynamic>?> _getUserApprovalStream(String uid) {
    _approvalStreamController?.close();
    _approvalPollingTimer?.cancel();

    final controller = StreamController<Map<String, dynamic>?>.broadcast();
    _approvalStreamController = controller;

    Future<void> fetch() async {
      if (controller.isClosed) return;
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select('approval_status')
            .eq('id', uid)
            .maybeSingle();
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (_) {
        if (!controller.isClosed) {
          controller.add(null);
        }
      }
    }

    fetch();
    _approvalPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetch());

    return controller.stream;
  }

  /// Returns a stream of the total notification count, polled every 30 seconds.
  Stream<int> _getTotalNotificationsCount() {
    _notificationStreamController?.close();
    _notificationPollingTimer?.cancel();

    final controller = StreamController<int>.broadcast();
    _notificationStreamController = controller;

    Future<void> fetch() async {
      if (controller.isClosed) return;
      try {
        final count = await _computeNotificationCount();
        if (!controller.isClosed) {
          controller.add(count);
        }
      } catch (_) {
        if (!controller.isClosed) {
          controller.add(0);
        }
      }
    }

    fetch();
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());

    return controller.stream;
  }

  Future<int> _computeNotificationCount() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return 0;

    // Récupérer les données de l'utilisateur courant (rôle + IDs lus)
    final currentUserData = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (currentUserData == null) return 0;

    final role = currentUserData['role'] as String? ?? '';
    final isAdmin = role == 'admin' || role.contains('admin');

    Set<String> readIds = {};
    Set<String> readMessageIds = {};
    final eventIds = currentUserData['read_notification_event_ids'];
    if (eventIds is List) readIds = eventIds.cast<String>().toSet();
    final msgIds = currentUserData['read_notification_message_ids'];
    if (msgIds is List) readMessageIds = msgIds.cast<String>().toSet();

    // Compter les adhésions selon le rôle
    int adherentsCount = 0;
    if (isAdmin) {
      // Admin : nombre de demandes d'adhésion en attente
      final pending = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('approval_status', 'pending');
      adherentsCount = (pending as List).length;
    } else {
      // Utilisateur : nouveaux membres approuvés (7 derniers jours) non vus
      final readMemberIds = currentUserData['read_new_member_ids'];
      final Set<String> readMemberIdSet = {};
      if (readMemberIds is List) {
        readMemberIdSet.addAll(readMemberIds.cast<String>());
      }
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final approvedMembers = await Supabase.instance.client
          .from('users')
          .select('id, approved_at')
          .eq('approval_status', 'approved');
      adherentsCount = (approvedMembers as List).where((doc) {
        final docId = doc['id'] as String?;
        if (docId == null || docId == uid) return false;
        if (readMemberIdSet.contains(docId)) return false;
        final approvedAtStr = doc['approved_at'] as String?;
        if (approvedAtStr == null) return false;
        final approvedAt = DateTime.tryParse(approvedAtStr);
        if (approvedAt == null) return false;
        return approvedAt.isAfter(sevenDaysAgo);
      }).length;
    }

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final events = await Supabase.instance.client
        .from('events')
        .select('id, created_at, date');

    final eventsCount = (events as List).where((doc) {
      final docId = doc['id'] as String?;
      if (docId == null) return false;
      if (readIds.contains(docId)) return false;
      final createdAtStr = doc['created_at'] as String?;
      if (createdAtStr == null) return false;
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) return false;
      final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      if (!createdDate.isAtSameMomentAs(todayStart) && createdDate.isBefore(todayStart)) {
        return false;
      }
      // Exclure les événements dont la date de rencontre est passée
      final eventDateStr = doc['date'] as String?;
      if (eventDateStr == null) return false;
      final eventDate = DateTime.tryParse(eventDateStr);
      if (eventDate == null) return false;
      final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      return !eventDay.isBefore(todayStart);
    }).length;

    final publishedMessages = await Supabase.instance.client
        .from('messages')
        .select('id')
        .eq('published', true);

    final messagesCount = (publishedMessages as List)
        .where((doc) => doc['id'] != null && !readMessageIds.contains(doc['id'] as String))
        .length;

    return adherentsCount + eventsCount + messagesCount;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.home, size: 28),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
        leadingWidth: 200,
        leading: Row(
          children: [
            const SizedBox(width: 4),
            // Bouton notifications avec badge
            StreamBuilder<int>(
              stream: _notificationCountStream ??= _getTotalNotificationsCount(),
              builder: (context, snapshot) {
                final notificationCount = snapshot.data ?? 0;
                return badges.Badge(
                  badgeContent: Text(
                    notificationCount > 99 ? '99+' : notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  showBadge: notificationCount > 0,
                  position: badges.BadgePosition.topEnd(top: 0, end: 4),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(4),
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mail_outline, size: 24),
                    tooltip: 'Notifications',
                  ),
                );
              },
            ),
            // Bouton toutes les rencontres
            StreamBuilder<user_model.User?>(
              stream: _authStream,
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user == null) return const SizedBox.shrink();
                return IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AllEventsPage(currentUser: user),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month, size: 24),
                  tooltip: 'Toutes les rencontres',
                );
              },
            ),
            // Bouton FAQ
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
            // Bouton paramètres
            IconButton(
              onPressed: () {
                final auth = context.read<AuthService>();
                final navigator = Navigator.of(context);
                auth.authStateChanges.first.then((user) {
                  if (user != null && mounted) {
                    navigator.push(
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
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 24),
            tooltip: 'Déconnexion',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<user_model.User?>(
        stream: _authStream,
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

          // Démarre le listener de blocage dès que l'utilisateur est connu
          _startBlockedListener(user.uid);

          // L'admin a toujours accès complet, même si le check CGU est en cours
          if (user.role == user_model.UserRole.admin) {
            return _buildMainContent(context, user);
          }

          if (!_cguCheckCompleted) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_userAcceptedCGU) {
            return _buildAccessDeniedScreen(context, user);
          }

          // Pour les autres utilisateurs, vérifier le statut d'approbation via polling
          if (_cachedApprovalUid != user.uid) {
            _cachedApprovalUid = user.uid;
            _approvalStream = _getUserApprovalStream(user.uid);
          }
          return StreamBuilder<Map<String, dynamic>?>(
            stream: _approvalStream,
            builder: (context, userDocSnap) {
              if (userDocSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = userDocSnap.data;
              final approvalStatus = data?['approval_status'] as String?;
              if (approvalStatus == 'rejected') {
                return _buildRejectedScreen(context, isDark);
              }
              if (approvalStatus != 'approved') {
                return _buildPendingApprovalScreen(context, isDark);
              }
              return _buildMainContent(context, user);
            },
          );
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
                color: Colors.orange.withValues(alpha: 0.1),
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

  Widget _buildPendingApprovalScreen(BuildContext context, bool isDark) {
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
                color: Colors.orange.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.hourglass_empty,
                size: 64,
                color: Colors.orange[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Validation en cours',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Votre demande d\'adhésion est en attente de validation par un administrateur. '
              'Vous recevrez une notification dès qu\'elle sera traitée.',
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
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedScreen(BuildContext context, bool isDark) {
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
                color: Colors.red.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.cancel_outlined,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Demande refusée',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Votre demande d\'adhésion a été refusée. '
              'Pour plus d\'informations, contactez l\'administration.',
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
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
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
                  Colors.blue[900]!.withValues(alpha: 0.3),
                  Colors.purple[900]!.withValues(alpha: 0.3),
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
          const SizedBox(height: 12),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: _ContactButton(
                icon: Icons.favorite_outline,
                label: 'Merci qui ?',
                color: Colors.green,
                onPressed: () =>
                    _showMessageDialog(context, user, 'Merci qui'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context, user_model.User user, String category) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => _MessageFormDialog(
        user: user,
        category: category,
      ),
    ));
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

        if (user.role == user_model.UserRole.admin)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminUsersPage(),
                  ),
                );
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Gérer les utilisateurs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
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
          stream: _eventsStream ??= _eventService.getAllEventsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Erreur: ${snapshot.error}'),
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

            // Événements terminés : FeedbackPrompt invisible déclenche le formulaire
            final finishedEvents = allEvents
                .where((event) => event.status == EventStatus.finished)
                .toList();

            return Column(
              children: [
                // Widgets invisibles qui déclenchent le feedback au bon moment
                ...finishedEvents.map((event) => FeedbackPrompt(
                  key: ValueKey('fp_${event.id}'),
                  event: event,
                )),
                if (upcomingEvents.isEmpty)
                  Center(
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
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcomingEvents.length,
                    itemBuilder: (context, index) {
                      return EventCard(
                        event: upcomingEvents[index],
                        isDark: isDark,
                        currentUser: user,
                        showParticipantCount: false,
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.showMaterialBanner(
                            MaterialBanner(
                              content: Text(
                                upcomingEvents[index].theme,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              leading: const Icon(Icons.event),
                              actions: [
                                TextButton(
                                  onPressed: () => messenger.hideCurrentMaterialBanner(),
                                  child: const Text('Fermer'),
                                ),
                              ],
                            ),
                          );
                          Future.delayed(const Duration(seconds: 4), () {
                            messenger.hideCurrentMaterialBanner();
                          });
                        },
                      );
                    },
                  ),
              ],
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

/// Formulaire simple pour écrire un message (stocké dans Supabase)
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
  final TextEditingController _linkController = TextEditingController();
  final StorageService _storageService = StorageService();
  bool _isSending = false;
  String? _error;

  XFile? _imageFile;
  Uint8List? _imageBytes;
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageFile = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.any,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
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
      final ts = DateTime.now().millisecondsSinceEpoch;
      String? imageUrl;
      String? fileUrl;
      String? fileName;

      if (_imageFile != null && _imageBytes != null) {
        final ext = _imageFile!.name.split('.').last;
        imageUrl = await _storageService.uploadFile(
          bucket: 'messages_attachments',
          path: '${widget.user.uid}/${ts}_image.$ext',
          bytes: _imageBytes!,
        );
      }

      if (_pickedFile != null && _pickedFile!.bytes != null) {
        fileName = _pickedFile!.name;
        fileUrl = await _storageService.uploadFile(
          bucket: 'messages_attachments',
          path: '${widget.user.uid}/${ts}_$fileName',
          bytes: _pickedFile!.bytes!,
        );
      }

      final link = _linkController.text.trim();

      await Supabase.instance.client.from('messages').insert({
        'user_id': widget.user.uid,
        'user_name': '${widget.user.prenom} ${widget.user.nom}',
        'user_email': widget.user.email,
        'user_role': widget.user.role.toString(),
        'category': widget.category,
        'message': _messageController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        if (link.isNotEmpty) 'link_url': link,
        if (imageUrl != null) 'image_url': imageUrl,
        if (fileUrl != null) 'file_url': fileUrl,
        if (fileName != null) 'file_name': fileName,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message enregistré avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error: $e');
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        elevation: 0,
        backgroundColor:
            isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
        actions: [
          TextButton(
            onPressed: _isSending ? null : _submitMessage,
            child: Text(
              'Envoyer',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre message:',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 10,
              minLines: 8,
              enabled: !_isSending,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: widget.category == 'Merci qui'
                    ? 'Indiquez qui vous a aidé et comment...'
                    : 'Écrivez votre message ici...',
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
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Pièces jointes (optionnel)',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Champ lien
            TextField(
              controller: _linkController,
              enabled: !_isSending,
              keyboardType: TextInputType.url,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Lien (URL)',
                hintText: 'https://...',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            // Boutons photo / fichier
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSending ? null : _pickImage,
                    icon: const Icon(Icons.photo_camera, size: 18),
                    label: Text(_imageFile != null ? 'Changer photo' : 'Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSending ? null : _pickFile,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(_pickedFile != null ? 'Changer fichier' : 'Fichier'),
                  ),
                ),
              ],
            ),
            // Aperçu image
            if (_imageBytes != null) ...[
              const SizedBox(height: 12),
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
                        _imageFile = null;
                        _imageBytes = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Nom du fichier sélectionné
            if (_pickedFile != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, size: 20, color: Colors.orange[700]),
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
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            ],
            // Indicateur d'envoi
            if (_isSending) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              Text(
                'Envoi en cours...',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
