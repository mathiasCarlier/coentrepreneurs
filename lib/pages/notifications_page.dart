// pages/notifications_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coentrepreneurs/widgets/fullscreen_image_viewer.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0 = Adhésions, 1 = Événements, 2 = Messages
  final Set<String> _readEventIds = {};
  final Set<String> _readMessageIds = {};
  final Set<String> _readNewMemberIds = {};
  bool _isAdmin = false;

  // Données chargées manuellement (pas de Realtime pour users)
  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _approvedMembers = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadReadIds();
    _loadUserInfo();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (mounted) setState(() => _loadingUsers = true);
    await Future.wait([_fetchPendingUsers(), _fetchApprovedMembers()]);
    if (mounted) setState(() => _loadingUsers = false);
  }

  Future<void> _fetchPendingUsers() async {
    try {
      final rows = await Supabase.instance.client
          .from('users')
          .select()
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);
      _pendingUsers = (rows as List).map((row) {
        DateTime? createdAt;
        final ca = row['created_at'];
        if (ca != null) createdAt = DateTime.tryParse(ca as String);
        return {
          'id': row['id'] as String,
          'prenom': row['prenom'] ?? '',
          'nom': row['nom'] ?? '',
          'email': row['email'] ?? '',
          'phone': row['phone'] ?? '',
          'createdAt': createdAt,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur chargement pending users: $e');
    }
  }

  Future<void> _fetchApprovedMembers() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final currentUid = Supabase.instance.client.auth.currentUser?.id;
      final rows = await Supabase.instance.client
          .from('users')
          .select()
          .eq('approval_status', 'approved')
          .gte('approved_at', sevenDaysAgo.toIso8601String())
          .order('approved_at', ascending: false);
      _approvedMembers = (rows as List).where((row) {
        return row['id'] != currentUid;
      }).map((row) {
        DateTime? approvedAt;
        final aa = row['approved_at'];
        if (aa != null) approvedAt = DateTime.tryParse(aa as String);
        return {
          'id': row['id'] as String,
          'prenom': row['prenom'] ?? '',
          'nom': row['nom'] ?? '',
          'email': row['email'] ?? '',
          'approvedAt': approvedAt,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur chargement approved members: $e');
    }
  }

  Future<void> _loadReadIds() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final data = await Supabase.instance.client
        .from('users')
        .select('read_notification_event_ids, read_notification_message_ids, read_new_member_ids')
        .eq('id', uid)
        .maybeSingle();
    final eventIds = data?['read_notification_event_ids'];
    if (eventIds is List && mounted) {
      setState(() => _readEventIds.addAll(eventIds.whereType<String>()));
    }
    final messageIds = data?['read_notification_message_ids'];
    if (messageIds is List && mounted) {
      setState(() => _readMessageIds.addAll(messageIds.whereType<String>()));
    }
    final memberIds = data?['read_new_member_ids'];
    if (memberIds is List && mounted) {
      setState(() => _readNewMemberIds.addAll(memberIds.whereType<String>()));
    }
  }

  Future<void> _loadUserInfo() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final data = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    final role = data?['role'] as String? ?? '';
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin' || role.contains('admin');
      });
    }
  }

  Future<void> _markAsRead(String eventId) async {
    setState(() => _readEventIds.add(eventId));
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final userData = await Supabase.instance.client
        .from('users')
        .select('read_notification_event_ids')
        .eq('id', uid)
        .maybeSingle();
    final currentIds = List<String>.from(userData?['read_notification_event_ids'] ?? []);
    if (!currentIds.contains(eventId)) {
      currentIds.add(eventId);
      await Supabase.instance.client
          .from('users')
          .update({'read_notification_event_ids': currentIds}).eq('id', uid);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    const allowed = {'http', 'https', 'tel', 'mailto'};
    if (!allowed.contains(uri.scheme)) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
    setState(() => _readMessageIds.add(messageId));
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final userData = await Supabase.instance.client
        .from('users')
        .select('read_notification_message_ids')
        .eq('id', uid)
        .maybeSingle();
    final currentIds = List<String>.from(userData?['read_notification_message_ids'] ?? []);
    if (!currentIds.contains(messageId)) {
      currentIds.add(messageId);
      await Supabase.instance.client
          .from('users')
          .update({'read_notification_message_ids': currentIds}).eq('id', uid);
    }
  }

  Stream<List<Map<String, dynamic>>> _getPublishedMessages() {
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final published = rows.where((row) => row['published'] == true).map((row) {
        DateTime? timestamp;
        final ts = row['timestamp'];
        if (ts != null) {
          timestamp = DateTime.tryParse(ts as String);
        }
        return {
          'id': row['id'] as String,
          'userName': row['userName'] ?? row['user_name'] ?? '',
          'category': row['category'] ?? '',
          'message': row['message'] ?? '',
          'timestamp': timestamp,
          'linkUrl': row['linkUrl'] as String? ?? row['link_url'] as String?,
          'imageUrl': row['imageUrl'] as String? ?? row['image_url'] as String?,
          'fileUrl': row['fileUrl'] as String? ?? row['file_url'] as String?,
          'fileName': row['fileName'] as String? ?? row['file_name'] as String?,
        };
      }).toList();

      published.sort((a, b) {
        final ta = a['timestamp'] as DateTime?;
        final tb = b['timestamp'] as DateTime?;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

      return published;
    });
  }

  Future<void> _approveUser(String uid, String prenom, String nom) async {
    try {
      await Supabase.instance.client.from('users').update({
        'approval_status': 'approved',
        'approved_at': DateTime.now().toIso8601String(),
        'role': 'adherent',
      }).eq('id', uid);
      await _loadUsers(); // Recharge les listes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$prenom $nom a été approuvé(e) comme adhérent(e).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectUser(String uid, String prenom, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la demande ?'),
        content: Text(
          'La demande de $prenom $nom sera refusée et son accès sera bloqué.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Refuser',
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
    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('users').update({
        'approval_status': 'rejected',
        'blocked': true,
      }).eq('id', uid);
      await _loadUsers(); // Recharge les listes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La demande de $prenom $nom a été refusée.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markNewMemberAsSeen(String memberId) async {
    setState(() => _readNewMemberIds.add(memberId));
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final userData = await Supabase.instance.client
        .from('users')
        .select('read_new_member_ids')
        .eq('id', uid)
        .maybeSingle();
    final currentIds = List<String>.from(userData?['read_new_member_ids'] ?? []);
    if (!currentIds.contains(memberId)) {
      currentIds.add(memberId);
      await Supabase.instance.client
          .from('users')
          .update({'read_new_member_ids': currentIds}).eq('id', uid);
    }
  }

  // Stream pour les nouveaux événements créés
  Stream<List<Map<String, dynamic>>> _getNewEvents() {
    return Supabase.instance.client
        .from('events')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final filtered = rows.where((row) {
        final createdAtRaw = row['created_at'];
        if (createdAtRaw == null) return false;
        final createdAt = DateTime.tryParse(createdAtRaw as String);
        if (createdAt == null) return false;
        final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
        if (!createdDate.isAtSameMomentAs(todayStart) && createdDate.isBefore(todayStart)) {
          return false;
        }
        // Exclure les événements dont la date de rencontre est passée
        final eventDateRaw = row['date'];
        if (eventDateRaw == null) return false;
        final eventDate = DateTime.tryParse(eventDateRaw as String);
        if (eventDate == null) return false;
        final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
        return !eventDay.isBefore(todayStart);
      }).map((row) {
        final eventDate = DateTime.tryParse(row['date'] as String) ?? DateTime.now();
        final createdAt = DateTime.tryParse(row['created_at'] as String) ?? DateTime.now();
        return {
          'id': row['id'] as String,
          'theme': row['theme'] ?? 'Événement',
          'date': eventDate,
          'lieu': row['lieu'] ?? '',
          'createdAt': createdAt,
        };
      }).toList();

      filtered.sort((a, b) {
        final ta = a['createdAt'] as DateTime;
        final tb = b['createdAt'] as DateTime;
        return tb.compareTo(ta);
      });

      return filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Onglets
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? Colors.blue
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.person_add, size: 22),
                          const SizedBox(height: 4),
                          const Text('Adhésions', style: TextStyle(fontSize: 12)),
                          Builder(
                            builder: (context) {
                              final count = _isAdmin
                                  ? _pendingUsers.length
                                  : _approvedMembers.where((m) => !_readNewMemberIds.contains(m['id'])).length;
                              if (count == 0) return const SizedBox.shrink();

                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? Colors.blue
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.event, size: 22),
                          const SizedBox(height: 4),
                          const Text('Rencontres', style: TextStyle(fontSize: 12)),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _getNewEvents(),
                            builder: (context, snapshot) {
                              final count = (snapshot.data ?? [])
                                  .where((e) => !_readEventIds.contains(e['id']))
                                  .length;
                              if (count == 0) return const SizedBox.shrink();

                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 2
                                ? Colors.blue
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.campaign, size: 22),
                          const SizedBox(height: 4),
                          const Text('Messages', style: TextStyle(fontSize: 12)),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _getPublishedMessages(),
                            builder: (context, snapshot) {
                              final count = (snapshot.data ?? [])
                                  .where((m) => !_readMessageIds.contains(m['id']))
                                  .length;
                              if (count == 0) return const SizedBox.shrink();

                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: _selectedTab == 0
                ? _buildAdherentsTab(isDark)
                : _selectedTab == 1
                    ? _buildEventsTab(isDark)
                    : _buildMessagesTab(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherentsTab(bool isDark) {
    if (_isAdmin) {
      return _buildPendingApprovalsView(isDark);
    }
    return _buildNewMembersView(isDark);
  }

  // Vue admin : demandes en attente
  Widget _buildPendingApprovalsView(bool isDark) {
        if (_loadingUsers) {
          return const Center(child: CircularProgressIndicator());
        }

        final pending = _pendingUsers;

        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune demande en attente',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous êtes à jour !',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final user = pending[index];
            final uid = user['id'] as String;
            final prenom = user['prenom'] as String;
            final nom = user['nom'] as String;
            final email = user['email'] as String;
            final phone = user['phone'] as String;
            final createdAt = user['createdAt'] as DateTime?;
            final formattedDate = createdAt != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
                : 'Date inconnue';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange[100],
                          ),
                          child: Icon(Icons.person, color: Colors.orange[700]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$prenom $nom',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              if (phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: Text(
                            'En attente',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Demande reçue le $formattedDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveUser(uid, prenom, nom),
                            icon: const Icon(Icons.check, size: 18, color: Colors.white),
                            label: const Text(
                              'Approuver',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _rejectUser(uid, prenom, nom),
                            icon: const Icon(Icons.close, size: 18, color: Colors.white),
                            label: const Text(
                              'Refuser',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }

  // Vue utilisateur : nouveaux membres approuvés
  Widget _buildNewMembersView(bool isDark) {
        if (_loadingUsers) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMembers = _approvedMembers;

        if (allMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun nouveau membre',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous êtes à jour !',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final unread = allMembers.where((m) => !_readNewMemberIds.contains(m['id'])).toList();
        final read = allMembers.where((m) => _readNewMemberIds.contains(m['id'])).toList();
        final sorted = [...unread, ...read];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final member = sorted[index];
            final memberId = member['id'] as String;
            final isRead = _readNewMemberIds.contains(memberId);
            final approvedAt = member['approvedAt'] as DateTime?;
            final formattedDate = approvedAt != null
                ? DateFormat('dd/MM/yyyy').format(approvedAt)
                : 'Date inconnue';

            return Opacity(
              opacity: isRead ? 0.6 : 1.0,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isRead
                    ? (isDark ? Colors.grey[850] : Colors.grey[100])
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isRead
                                  ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                                  : Colors.green[100]!,
                            ),
                            child: Icon(
                              Icons.person_add,
                              color: isRead
                                  ? (isDark ? Colors.grey[600]! : Colors.grey[400]!)
                                  : Colors.green[700]!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${member['prenom']} ${member['nom']}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    color: isRead
                                        ? (isDark ? Colors.grey[500] : Colors.grey[500])
                                        : null,
                                  ),
                                ),
                                Text(
                                  'Nouveau membre · $formattedDate',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isRead)
                            Icon(Icons.check_circle, size: 18, color: Colors.grey[400]),
                        ],
                      ),
                      if (!isRead) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _markNewMemberAsSeen(memberId),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Marquer comme vu'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }

  Widget _buildMessagesTab(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getPublishedMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final allMessages = snapshot.data ?? [];

        if (allMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign, size: 64, color: Colors.orange[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun message publié',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous êtes à jour !',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final unread = allMessages.where((m) => !_readMessageIds.contains(m['id'])).toList();
        final read = allMessages.where((m) => _readMessageIds.contains(m['id'])).toList();
        final sorted = [...unread, ...read];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final msg = sorted[index];
            final isRead = _readMessageIds.contains(msg['id'] as String);
            final timestamp = msg['timestamp'] as DateTime?;
            final formattedDate = timestamp != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
                : 'Date inconnue';

            final iconColor = isRead
                ? (isDark ? Colors.grey[600]! : Colors.grey[400]!)
                : Colors.orange[700]!;
            final iconBgColor = isRead
                ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                : Colors.orange[100]!;
            final titleColor = isRead
                ? (isDark ? Colors.grey[500] : Colors.grey[500])
                : null;

            return Opacity(
              opacity: isRead ? 0.6 : 1.0,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isRead
                    ? (isDark ? Colors.grey[850] : Colors.grey[100])
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconBgColor,
                            ),
                            child: Icon(
                              isRead ? Icons.mark_email_read : Icons.campaign,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['userName'] as String,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  msg['category'] as String,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isRead)
                            Icon(Icons.check_circle, size: 18, color: Colors.grey[400]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg['message'] as String,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: titleColor,
                          ),
                        ),
                      ),
                      // Lien
                      if (msg['linkUrl'] != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => _launchUrl(msg['linkUrl'] as String),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    msg['linkUrl'] as String,
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      decoration: TextDecoration.underline,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.open_in_new, size: 14, color: Colors.blue[700]),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Image
                      if (msg['imageUrl'] != null) ...[
                        const SizedBox(height: 10),
                        FullscreenImageViewer(
                          imageUrl: msg['imageUrl'] as String,
                          thumbnailHeight: 180,
                        ),
                      ],
                      // Fichier
                      if (msg['fileUrl'] != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => _launchUrl(msg['fileUrl'] as String),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
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
                                    msg['fileName'] as String? ?? 'Télécharger le fichier',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.download, size: 18, color: Colors.orange[700]),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedDate,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _markMessageAsRead(msg['id'] as String),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Marquer comme vu'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventsTab(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getNewEvents(),
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

        if (allEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.blue[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun nouvel événement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous êtes à jour !',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Non lus en premier (desc), lus en dessous (desc)
        final unread = allEvents.where((e) => !_readEventIds.contains(e['id'])).toList();
        final read = allEvents.where((e) => _readEventIds.contains(e['id'])).toList();
        final sorted = [...unread, ...read];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final event = sorted[index];
            final isRead = _readEventIds.contains(event['id'] as String);
            final eventDate = event['date'] as DateTime;
            final formattedEventDate = DateFormat('dd/MM/yyyy').format(eventDate);

            final iconColor = isRead
                ? (isDark ? Colors.grey[600]! : Colors.grey[400]!)
                : Colors.blue[700]!;
            final iconBgColor = isRead
                ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                : Colors.blue[100]!;
            final titleColor = isRead
                ? (isDark ? Colors.grey[500] : Colors.grey[500])
                : null;

            return Opacity(
              opacity: isRead ? 0.6 : 1.0,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isRead
                    ? (isDark ? Colors.grey[850] : Colors.grey[100])
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconBgColor,
                            ),
                            child: Icon(
                              isRead ? Icons.event_available : Icons.event,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              event['theme'],
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          ),
                          if (isRead)
                            Icon(Icons.check_circle, size: 18, color: Colors.grey[400]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedEventDate,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _markAsRead(event['id'] as String),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Marquer comme lu'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
