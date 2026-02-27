// pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _loadReadIds();
    _loadUserInfo();
  }

  Future<void> _loadReadIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final eventIds = doc.data()?['readNotificationEventIds'];
    if (eventIds is List && mounted) {
      setState(() => _readEventIds.addAll(eventIds.cast<String>()));
    }
    final messageIds = doc.data()?['readNotificationMessageIds'];
    if (messageIds is List && mounted) {
      setState(() => _readMessageIds.addAll(messageIds.cast<String>()));
    }
    final memberIds = doc.data()?['readNewMemberIds'];
    if (memberIds is List && mounted) {
      setState(() => _readNewMemberIds.addAll(memberIds.cast<String>()));
    }
  }

  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = doc.data()?['role'] as String? ?? '';
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin' || role.contains('admin');
      });
    }
  }

  Future<void> _markAsRead(String eventId) async {
    setState(() => _readEventIds.add(eventId));
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'readNotificationEventIds': FieldValue.arrayUnion([eventId]),
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
    setState(() => _readMessageIds.add(messageId));
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'readNotificationMessageIds': FieldValue.arrayUnion([messageId]),
    });
  }

  Stream<List<Map<String, dynamic>>> _getPublishedMessages() {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userName': data['userName'] ?? '',
          'category': data['category'] ?? '',
          'message': data['message'] ?? '',
          'timestamp': data['timestamp'] as Timestamp?,
          'linkUrl': data['linkUrl'] as String?,
          'imageUrl': data['imageUrl'] as String?,
          'fileUrl': data['fileUrl'] as String?,
          'fileName': data['fileName'] as String?,
        };
      }).toList()
        ..sort((a, b) {
          final ta = a['timestamp'] as Timestamp?;
          final tb = b['timestamp'] as Timestamp?;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });
    });
  }

  // Stream admin : utilisateurs en attente d'approbation
  Stream<List<Map<String, dynamic>>> _getPendingUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'prenom': data['prenom'] ?? '',
          'nom': data['nom'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'createdAt': data['createdAt'] as Timestamp?,
        };
      }).toList()
        ..sort((a, b) {
          final ta = a['createdAt'] as Timestamp?;
          final tb = b['createdAt'] as Timestamp?;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });
    });
  }

  // Stream utilisateurs : nouveaux membres approuvés (7 derniers jours)
  Stream<List<Map<String, dynamic>>> _getApprovedMembers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      return snapshot.docs
          .where((doc) {
            if (doc.id == currentUid) return false;
            final approvedAt = doc.data()['approvedAt'] as Timestamp?;
            if (approvedAt == null) return false;
            return approvedAt.toDate().isAfter(sevenDaysAgo);
          })
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'prenom': data['prenom'] ?? '',
              'nom': data['nom'] ?? '',
              'email': data['email'] ?? '',
              'approvedAt': data['approvedAt'] as Timestamp?,
            };
          })
          .toList()
          ..sort((a, b) {
            final ta = a['approvedAt'] as Timestamp?;
            final tb = b['approvedAt'] as Timestamp?;
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });
    });
  }

  Future<void> _approveUser(String uid, String prenom, String nom) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'role': 'adherent',
      });
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
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'approvalStatus': 'rejected',
        'blocked': true,
      });
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'readNewMemberIds': FieldValue.arrayUnion([memberId]),
    });
  }

  // Stream pour les nouveaux événements créés
  Stream<List<Map<String, dynamic>>> _getNewEvents() {
    return FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt == null) return false;
            final createdDate = DateTime(
              createdAt.toDate().year,
              createdAt.toDate().month,
              createdAt.toDate().day,
            );
            if (!createdDate.isAtSameMomentAs(todayStart) && createdDate.isBefore(todayStart)) {
              return false;
            }
            // Exclure les événements dont la date de rencontre est passée
            final eventDateTs = data['date'] as Timestamp?;
            if (eventDateTs == null) return false;
            final eventDay = DateTime(
              eventDateTs.toDate().year,
              eventDateTs.toDate().month,
              eventDateTs.toDate().day,
            );
            return !eventDay.isBefore(todayStart);
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return {
              'id': doc.id,
              'theme': data['theme'] ?? 'Événement',
              'date': (data['date'] as Timestamp).toDate(),
              'lieu': data['lieu'] ?? '',
              'createdAt': data['createdAt'] as Timestamp,
            };
          })
          .toList()
          ..sort((a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
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
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _isAdmin ? _getPendingUsers() : _getApprovedMembers(),
                            builder: (context, snapshot) {
                              final data = snapshot.data ?? [];
                              final count = _isAdmin
                                  ? data.length
                                  : data.where((m) => !_readNewMemberIds.contains(m['id'])).length;
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getPendingUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final pending = snapshot.data ?? [];

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
            final createdAt = user['createdAt'] as Timestamp?;
            final formattedDate = createdAt != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
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
      },
    );
  }

  // Vue utilisateur : nouveaux membres approuvés
  Widget _buildNewMembersView(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getApprovedMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final allMembers = snapshot.data ?? [];

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
            final approvedAt = member['approvedAt'] as Timestamp?;
            final formattedDate = approvedAt != null
                ? DateFormat('dd/MM/yyyy').format(approvedAt.toDate())
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
            final timestamp = msg['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
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
                        GestureDetector(
                          onTap: () => _launchUrl(msg['imageUrl'] as String),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              msg['imageUrl'] as String,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  height: 180,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (_, _, _) => Container(
                                height: 60,
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                              ),
                            ),
                          ),
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