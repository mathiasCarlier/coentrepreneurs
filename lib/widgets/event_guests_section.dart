// widgets/event_guests_section.dart - CORRIGÉ
// Affiche les ADHÉRENTS INSCRITS à l'événement (pas les invités)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;

class EventGuestsSection extends StatefulWidget {
  final String eventId;
  final bool isDark;
  final List<String> registeredUserIds; // ✅ AJOUTÉ: IDs des adhérents inscrits

  const EventGuestsSection({
    super.key,
    required this.eventId,
    required this.isDark,
    required this.registeredUserIds, // ✅ AJOUTÉ
  });

  @override
  State<EventGuestsSection> createState() => _EventGuestsSectionState();
}

class _EventGuestsSectionState extends State<EventGuestsSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère les données des adhérents inscrits
  /// ✅ CORRIGÉ: Affiche les adhérents, pas les invités
  Future<List<Map<String, dynamic>>> _fetchRegisteredUsers() async {
    try {
      debugPrint('🔍 Récupération des adhérents inscrits: ${widget.registeredUserIds.length}');

        if (widget.registeredUserIds.isEmpty) {
        debugPrint('⚠️ Aucun adhérent inscrit');
        return [];
      }

      final List<Map<String, dynamic>> result = [];

      for (final userId in widget.registeredUserIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();

          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            debugPrint('✅ Adhérent trouvé: $userId');

            result.add({
              'userId': userId,
              'user': user_model.User(
                uid: userId,
                email: userData['email'] ?? '',
                nom: userData['nom'] ?? 'Inconnu',
                prenom: userData['prenom'] ?? '',
                role: _stringToUserRole(userData['role'] ?? 'adherent'),
                phone: userData['telephone'] ?? '',
              ),
            });
          } else {
            debugPrint('⚠️ Adhérent $userId n\'existe pas');
          }
        } catch (e) {
          debugPrint('❌ Erreur lors de la récupération de l\'adhérent $userId: $e');
        }
      }

      debugPrint('📊 Résultat final: ${result.length} adhérents');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur globale: $e');
      return [];
    }
  }

  /// Convertit une string en UserRole
  user_model.UserRole _stringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return user_model.UserRole.admin;
      case 'invite':
        return user_model.UserRole.invite;
      case 'adherent':
      default:
        return user_model.UserRole.adherent;
    }
  }

  /// Supprime un adhérent de l'événement
  Future<void> _removeGuest(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'adhérent'),
        content: const Text('Êtes-vous sûr de vouloir retirer cet adhérent de l\'événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
      debugPrint('🗑️ Retrait de l\'adhérent: $userId');

        // ✅ Retirer l'adhérent de la liste registeredUserIds
        await _firestore.collection('events').doc(widget.eventId).update({
          'registeredUserIds': FieldValue.arrayRemove([userId]),
        });

        debugPrint('✅ Adhérent retiré');

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Adhérent retiré de l\'événement'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Erreur retrait: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📋 Titre
        Row(
          children: [
            Icon(Icons.people, size: 24, color: Colors.blue[600]),
            const SizedBox(width: 16),
            Text(
              'Adhérents inscrits (${widget.registeredUserIds.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.grey[200] : Colors.grey[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 📝 Liste des adhérents
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchRegisteredUsers(),
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
                  'Erreur: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              );
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucun adhérent inscrit',
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
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index]['user'] as user_model.User;
                final userId = users[index]['userId'] as String;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 👤 Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '${user.prenom[0]}${user.nom[0]}'.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 📌 Informations
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.prenom} ${user.nom}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🎯 Badge rôle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role == user_model.UserRole.admin ? '👑 Admin' : '✅ Adhérent',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 🗑️ Bouton supprimer
                        _ActionButton(
                          icon: Icons.delete,
                          color: Colors.red,
                          tooltip: 'Retirer',
                          onPressed: () => _removeGuest(userId),
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

/// Widget bouton action réutilisable
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}