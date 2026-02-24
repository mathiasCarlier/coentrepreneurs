// pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0 = Adhésions, 1 = Événements
  final Set<String> _readEventIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadIds();
  }

  Future<void> _loadReadIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final ids = doc.data()?['readNotificationEventIds'];
    if (ids is List && mounted) {
      setState(() => _readEventIds.addAll(ids.cast<String>()));
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

  // Stream pour les nouvelles adhésions (adhérents uniquement)
  Stream<List<Map<String, dynamic>>> _getNewAdherents() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'UserRole.adherent')
        .snapshots()
        .map((snapshot) {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final createdAt = data['createdAt'] as Timestamp?;
            if (createdAt == null) return false;
            return createdAt.toDate().isAfter(oneDayAgo);
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return {
              'id': doc.id,
              'prenom': data['prenom'] ?? '',
              'nom': data['nom'] ?? '',
              'email': data['email'] ?? '',
              'createdAt': data['createdAt'] as Timestamp,
            };
          })
          .toList()
          ..sort((a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                          const Icon(Icons.person_add, size: 24),
                          const SizedBox(height: 4),
                          const Text('Nouvelles adhésions'),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _getNewAdherents(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.length ?? 0;
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                          const Icon(Icons.event, size: 24),
                          const SizedBox(height: 4),
                          const Text('Nouveaux événements'),
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
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: _selectedTab == 0
                ? _buildAdherentsTab(isDark)
                : _buildEventsTab(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherentsTab(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getNewAdherents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final adherents = snapshot.data ?? [];

        if (adherents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune nouvelle adhésion',
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
          itemCount: adherents.length,
          itemBuilder: (context, index) {
            final adherent = adherents[index];
            final createdAt = adherent['createdAt'] as Timestamp;
            final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate());

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
                            color: Colors.green[100],
                          ),
                          child: Icon(
                            Icons.person_add,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${adherent['prenom']} ${adherent['nom']}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                adherent['email'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Inscrit le $formattedDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
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

        final events = (snapshot.data ?? [])
            .where((e) => !_readEventIds.contains(e['id']))
            .toList();

        if (events.isEmpty) {
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final eventDate = event['date'] as DateTime;
            final formattedEventDate = DateFormat('dd/MM/yyyy').format(eventDate);

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
                            color: Colors.blue[100],
                          ),
                          child: Icon(
                            Icons.event,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['theme'],
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}