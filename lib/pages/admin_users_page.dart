// pages/admin_users_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Stream de tous les utilisateurs non-admin, filtrés en Dart par rôle.
  /// On filtre en Dart pour éviter tout problème de format stocké ('adherent'
  /// vs 'UserRole.adherent').
  Stream<List<Map<String, dynamic>>> _getUsersStream(String targetRole) {
    return Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .map((data) {
      return data
          .where((u) {
            final stored = (u['role'] as String? ?? '').toLowerCase();
            return stored.contains(targetRole.toLowerCase());
          })
          .toList()
        ..sort((a, b) {
            final nameA = '${a['prenom'] ?? ''} ${a['nom'] ?? ''}';
            final nameB = '${b['prenom'] ?? ''} ${b['nom'] ?? ''}';
            return nameA.toLowerCase().compareTo(nameB.toLowerCase());
          });
    });
  }

  Future<void> _changeRole(String uid, String newRole) async {
    await Supabase.instance.client
        .from('users')
        .update({'role': newRole}).eq('id', uid);
  }

  Future<void> _toggleBlock(String uid, bool isCurrentlyBlocked) async {
    await Supabase.instance.client
        .from('users')
        .update({'blocked': !isCurrentlyBlocked}).eq('id', uid);
  }

  void _showRoleDialog(String uid, String currentRole, String userName) {
    // Normalise vers 'adherent' ou 'invite'
    final normalised = currentRole.toLowerCase().contains('adherent')
        ? 'adherent'
        : 'invite';
    String selectedRole = normalised;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Rôle de $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Radio<String>(
                  value: 'adherent',
                  groupValue: selectedRole,
                  onChanged: (v) =>
                      setDialogState(() => selectedRole = v!),
                ),
                title: const Text('Adhérent'),
                subtitle: const Text('Accès complet à l\'application'),
                onTap: () =>
                    setDialogState(() => selectedRole = 'adherent'),
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'invite',
                  groupValue: selectedRole,
                  onChanged: (v) =>
                      setDialogState(() => selectedRole = v!),
                ),
                title: const Text('Invité'),
                subtitle: const Text('Accès limité'),
                onTap: () =>
                    setDialogState(() => selectedRole = 'invite'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
              onPressed: selectedRole == normalised
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      try {
                        await _changeRole(uid, selectedRole);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Rôle mis à jour : ${selectedRole == 'adherent' ? 'Adhérent' : 'Invité'}',
                              ),
                              backgroundColor: Colors.green,
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
              child: Text(
                'Confirmer',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(String uid, bool isBlocked, String userName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isBlocked ? Icons.lock_open : Icons.block,
              color: isBlocked ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isBlocked ? 'Débloquer $userName ?' : 'Bloquer $userName ?',
              ),
            ),
          ],
        ),
        content: Text(
          isBlocked
              ? '$userName pourra à nouveau accéder à l\'application.'
              : '$userName ne pourra plus se connecter ni utiliser l\'application. '
                'L\'accès sera coupé immédiatement.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await _toggleBlock(uid, isBlocked);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isBlocked
                            ? '$userName a été débloqué'
                            : '$userName a été bloqué',
                      ),
                      backgroundColor:
                          isBlocked ? Colors.green : Colors.orange,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.green : Colors.red,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            child: Text(isBlocked ? 'Débloquer' : 'Bloquer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUid = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        elevation: 0,
        backgroundColor:
            isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            _buildTabWithCount('Adhérents', Icons.badge, 'adherent'),
            _buildTabWithCount('Invités', Icons.person_outline, 'invite'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          // Listes
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('adherent', currentUid, isDark),
                _buildUserList('invite', currentUid, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabWithCount(String label, IconData icon, String role) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getUsersStream(role),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserList(
    String role,
    String? currentUid,
    bool isDark,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getUsersStream(role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final allUsers = snapshot.data ?? [];
        final users = _searchQuery.isEmpty
            ? allUsers
            : allUsers.where((u) {
                final name =
                    '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.toLowerCase();
                final email =
                    (u['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) ||
                    email.contains(_searchQuery);
              }).toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  role == 'adherent' ? Icons.badge : Icons.person_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'Aucun ${role == 'adherent' ? 'adhérent' : 'invité'}'
                      : 'Aucun résultat pour "$_searchQuery"',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final uid = user['id'] as String;
            final prenom = user['prenom'] as String? ?? '';
            final nom = user['nom'] as String? ?? '';
            final email = user['email'] as String? ?? '';
            final isBlocked = user['blocked'] == true;
            final isCurrentUser = uid == currentUid;

            final initials =
                '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
                    .toUpperCase();

            final Color avatarBg = isBlocked
                ? Colors.red[100]!
                : role == 'adherent'
                    ? Colors.blue[100]!
                    : Colors.orange[100]!;
            final Color avatarFg = isBlocked
                ? Colors.red[700]!
                : role == 'adherent'
                    ? Colors.blue[700]!
                    : Colors.orange[700]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: isBlocked
                  ? (isDark ? Colors.grey[850] : Colors.red[50])
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Avatar avec initiales
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarBg,
                      ),
                      child: Center(
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: avatarFg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Infos utilisateur
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$prenom $nom',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isBlocked
                                            ? Colors.grey[500]
                                            : null,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBlocked)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.block,
                                          size: 12, color: Colors.red[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Bloqué',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Menu d'actions (masqué pour l'admin lui-même)
                    if (!isCurrentUser)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onSelected: (value) {
                          if (value == 'role') {
                            _showRoleDialog(
                              uid,
                              role,
                              '$prenom $nom',
                            );
                          } else if (value == 'block') {
                            _showBlockDialog(uid, isBlocked, '$prenom $nom');
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'role',
                            child: Row(
                              children: [
                                Icon(Icons.swap_horiz, size: 20),
                                SizedBox(width: 12),
                                Text('Changer le rôle'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'block',
                            child: Row(
                              children: [
                                Icon(
                                  isBlocked ? Icons.lock_open : Icons.block,
                                  size: 20,
                                  color:
                                      isBlocked ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isBlocked ? 'Débloquer' : 'Bloquer',
                                  style: TextStyle(
                                    color: isBlocked
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Moi',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
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
}
