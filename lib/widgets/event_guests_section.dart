import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coentrepreneurs/models/invitation.dart';
import 'package:coentrepreneurs/models/user.dart';
import 'package:coentrepreneurs/widgets/invitation_dialog.dart';

class EventGuestsSection extends StatefulWidget {
  final String eventId;
  final bool isDark;

  const EventGuestsSection({
    super.key,
    required this.eventId,
    required this.isDark,
  });

  @override
  State<EventGuestsSection> createState() => _EventGuestsSectionState();
}

class _EventGuestsSectionState extends State<EventGuestsSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crée un nouvel utilisateur avec le rôle "invite"
  /// ✅ CORRIGÉ: Crée TOUJOURS dans users/, même si email existe
  Future<String> _createInviteUser({
    required String email,
    required String prenom,
    required String nom,
  }) async {
    try {
      print('🔍 Création de l\'utilisateur invite: $email');

      // Vérifier si l'utilisateur existe déjà avec cet email
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .get();

      if (existingUsers.docs.isNotEmpty) {
        print('✅ Utilisateur existe déjà: ${existingUsers.docs.first.id}');
        return existingUsers.docs.first.id;
      }

      print('📝 Création d\'un nouvel utilisateur...');

      // Créer un nouvel utilisateur avec rôle "invite"
      final newUserRef = _firestore.collection('users').doc();
      final userData = {
        'email': email.toLowerCase().trim(),
        'prenom': prenom.trim(),
        'nom': nom.trim(),
        'role': 'invite', // ✅ Rôle invite
        'telephone': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      print('📤 Enregistrement dans Firestore: $userData');
      await newUserRef.set(userData);

      print('✅ Utilisateur créé: ${newUserRef.id}');
      return newUserRef.id;
    } catch (e) {
      print('❌ Erreur lors de la création de l\'utilisateur invite: $e');
      rethrow;
    }
  }

  /// Récupère les invitations avec les données utilisateur
  Future<List<Map<String, dynamic>>> _fetchInvitationsWithUsers() async {
    try {
      print('🔍 Récupération des invitations pour event: ${widget.eventId}');

      final snapshot = await _firestore
          .collection('events')
          .doc(widget.eventId)
          .collection('invitations')
          .get();

      print('📊 Invitations trouvées: ${snapshot.docs.length}');

      final List<Map<String, dynamic>> result = [];

      for (final doc in snapshot.docs) {
        final invitationData = doc.data();
        final userId = invitationData['userId'] as String?;

        print('📌 Invitation ${doc.id}: userId=$userId');

        if (userId != null && userId.isNotEmpty) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() ?? {};
              print('✅ User trouvé: ${userDoc.id}');

              result.add({
                'invitationId': doc.id,
                'userId': userId,
                'user': User(
                  uid: userId,
                  email: userData['email'] ?? '',
                  nom: userData['nom'] ?? 'Inconnu',
                  prenom: userData['prenom'] ?? '',
                  role: _stringToUserRole(userData['role'] ?? 'invite'),
                  phone: userData['telephone'],
                ),
                'status': invitationData['status'] ?? 'pending',
                'createdAt': invitationData['createdAt'],
              });
            } else {
              print('⚠️ User $userId n\'existe pas');
            }
          } catch (e) {
            print('❌ Erreur lors de la récupération de l\'utilisateur $userId: $e');
          }
        } else {
          print('⚠️ Pas de userId pour l\'invitation ${doc.id}');
        }
      }

      print('📊 Résultat final: ${result.length} invitations avec users');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des invitations: $e');
      return [];
    }
  }

  /// Convertit une string en UserRole
  UserRole _stringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'invite':
        return UserRole.invite;
      default:
        return UserRole.adherent;
    }
  }

  /// Ajoute des invités à l'événement
  /// ✅ CORRIGÉ: Crée VRAIMENT les utilisateurs
  Future<void> _addGuests() async {
    final result = await showDialog<List<Map<String, String>>>(
      context: context,
      builder: (context) => InvitationDialog(
        eventId: widget.eventId,
        currentUserId: '',
        onInvitationSent: () {},
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      print('🎯 Ajout de ${result.length} invités');

      bool hasError = false;
      int successCount = 0;

      for (final guest in result) {
        try {
          final email = guest['email'] ?? '';
          final prenom = guest['prenom'] ?? '';
          final nom = guest['nom'] ?? '';

          print('\n📝 Traitement invité: $prenom $nom ($email)');

          if (email.isEmpty || prenom.isEmpty || nom.isEmpty) {
            throw Exception('Données invalides');
          }

          // 1️⃣ CRÉER OU RÉCUPÉRER L'UTILISATEUR
          print('   1️⃣ Création/récupération utilisateur...');
          final userId = await _createInviteUser(
            email: email,
            prenom: prenom,
            nom: nom,
          );
          print('   ✅ UserId: $userId');

          // 2️⃣ CRÉER L'ENREGISTREMENT D'INVITATION
          print('   2️⃣ Création invitation...');
          final invitationRef = await _firestore
              .collection('events')
              .doc(widget.eventId)
              .collection('invitations')
              .add({
            'userId': userId, // 🔑 IMPORTANT: Lien vers l'utilisateur
            'email': email.toLowerCase().trim(),
            'prenom': prenom.trim(),
            'nom': nom.trim(),
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

          print('   ✅ Invitation: ${invitationRef.id}');
          print('   ✅ Invité ajouté avec succès!\n');
          successCount++;
        } catch (e) {
          print('   ❌ Erreur pour ${guest['prenom']}: $e\n');
          hasError = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erreur pour ${guest['prenom']}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (mounted) {
        // Recharger les données
        print('🔄 Rechargement de la liste...');
        setState(() {});

        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $successCount invité(s) ajouté(s) avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  /// Accepte une invitation
  Future<void> _acceptInvitation(String invitationId, String userId) async {
    try {
      print('✅ Acceptation invitation: $invitationId');
      await _firestore
          .collection('events')
          .doc(widget.eventId)
          .collection('invitations')
          .doc(invitationId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Invitation acceptée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur acceptation: $e');
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

  /// Refuse une invitation
  Future<void> _declineInvitation(String invitationId, String userId) async {
    try {
      print('❌ Refus invitation: $invitationId');
      await _firestore
          .collection('events')
          .doc(widget.eventId)
          .collection('invitations')
          .doc(invitationId)
          .update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invitation refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur refus: $e');
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

  /// Supprime une invitation et l'utilisateur invite
  Future<void> _deleteGuest(String invitationId, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'invité'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet invité ?'),
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
        print('🗑️ Suppression invitation: $invitationId');

        // 1️⃣ Supprimer l'invitation
        await _firestore
            .collection('events')
            .doc(widget.eventId)
            .collection('invitations')
            .doc(invitationId)
            .delete();

        print('✅ Invitation supprimée');

        // 2️⃣ Vérifier si l'utilisateur est invité à d'autres événements
        print('🔍 Vérification d\'autres invitations pour $userId...');
        final otherInvitations = await _firestore
            .collectionGroup('invitations')
            .where('userId', isEqualTo: userId)
            .get();

        print('   Autres invitations trouvées: ${otherInvitations.docs.length}');

        if (otherInvitations.docs.isEmpty) {
          print('   Suppression de l\'utilisateur...');
          await _firestore.collection('users').doc(userId).delete();
          print('   ✅ Utilisateur supprimé');
        } else {
          print('   L\'utilisateur a d\'autres invitations, conservation.');
        }

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Invité supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Erreur suppression: $e');
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
        // 📋 Titre avec bouton Ajouter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, size: 24, color: Colors.blue[600]),
                const SizedBox(width: 16),
                Text(
                  'Invités',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.grey[200] : Colors.grey[900],
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _addGuests,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 📝 Liste des invités
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchInvitationsWithUsers(),
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

            final invitations = snapshot.data ?? [];

            if (invitations.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucun invité pour le moment',
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
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                final invitation = invitations[index];
                final user = invitation['user'] as User;
                final status = invitation['status'] as String;
                final invitationId = invitation['invitationId'] as String;
                final userId = invitation['userId'] as String;

                final isAccepted = status == 'accepted';
                final isDeclined = status == 'declined';
                final isPending = status == 'pending';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAccepted
                            ? Colors.green[400]!
                            : isDeclined
                                ? Colors.red[300]!
                                : Colors.orange[300]!,
                        width: isAccepted || isDeclined ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 👤 Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isAccepted
                                ? Colors.green[600]
                                : isDeclined
                                    ? Colors.red[400]
                                    : Colors.orange[600],
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

                        // 🎯 Badge Statut + Actions
                        if (isAccepted)
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
                              '✅ Accepté',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          )
                        else if (isDeclined)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '❌ Refusé',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                          )
                        else
                          // Boutons Accepter / Refuser
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                icon: Icons.check,
                                color: Colors.green,
                                tooltip: 'Accepter',
                                onPressed: () =>
                                    _acceptInvitation(invitationId, userId),
                              ),
                              const SizedBox(width: 4),
                              _ActionButton(
                                icon: Icons.close,
                                color: Colors.red,
                                tooltip: 'Refuser',
                                onPressed: () =>
                                    _declineInvitation(invitationId, userId),
                              ),
                              const SizedBox(width: 4),
                              _ActionButton(
                                icon: Icons.delete,
                                color: Colors.grey,
                                tooltip: 'Supprimer',
                                onPressed: () =>
                                    _deleteGuest(invitationId, userId),
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