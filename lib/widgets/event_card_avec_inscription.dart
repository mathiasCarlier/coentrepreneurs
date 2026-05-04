import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;
import 'package:coentrepreneurs/services/registration_service.dart';
import 'package:coentrepreneurs/services/location_service.dart';
import 'package:coentrepreneurs/widgets/invitation_dialog.dart';
import 'package:coentrepreneurs/services/invitation_service.dart';
import 'package:coentrepreneurs/widgets/collation_dialog.dart';

/// Carte interactive affichant une rencontre avec les actions disponibles
/// selon l'état de l'utilisateur vis-à-vis de l'événement.
///
/// Quatre vues s'affichent mutuellement de manière exclusive, par ordre de priorité :
/// 1. **Refusé** – carte compacte + bouton "Annuler le refus".
/// 2. **Confirmé** – badge vert "Présent", message de confirmation.
/// 3. **Inscrit** – badge état + bouton "Inviter quelqu'un" ou "Je suis présent".
/// 4. **Non inscrit** – détails complets + boutons "S'inscrire" / "Refuser".
///
/// Toutes les mutations passent par [RegistrationService] et [EventService].
class EventCard extends StatefulWidget {
  final Event event;
  final bool isDark;
  final user_model.User? currentUser;
  final bool showParticipantCount;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.isDark,
    this.currentUser,
    this.showParticipantCount = true,
    this.onTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevation;
  final RegistrationService _registrationService = RegistrationService();
  final InvitationService _invitationService = InvitationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _elevation = Tween<double>(begin: 2, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Use computed getters to determine registration state; no stored field needed.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isUserInscribed {
    return widget.currentUser != null
        ? widget.event.isUserRegistered(widget.currentUser!.uid)
        : false;
  }

  bool get _isUserConfirmed {
    return widget.currentUser != null
        ? widget.event.isUserConfirmed(widget.currentUser!.uid)
        : false;
  }

  bool get _isUserDeclined {
    return widget.currentUser != null
        ? widget.event.isUserDeclined(widget.currentUser!.uid)
        : false;
  }

  Future<void> _toggleRegistration() async {
    if (widget.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour vous inscrire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Empêcher la désinscription si l'événement a commencé
    if (_isUserInscribed && widget.event.isStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Impossible d\'annuler après le début de l\'événement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isUserInscribed) {
        // Désinscrire (seulement si événement pas commencé)
        await _registrationService.unregisterUserFromEvent(
          widget.event.id,
          widget.currentUser!.uid,
        );
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Vous avez annulé votre inscription'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // Vérifier si inscriptions toujours ouvertes (événement pas commencé)
        if (widget.event.isStarted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Les inscriptions sont fermées'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Vérifier la capacité
        if (widget.event.isFull) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Cet événement est complet'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Inscrire
        await _registrationService.registerUserToEvent(
          widget.event.id,
          widget.currentUser!.uid,
        );
        if (mounted) {
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Inscription confirmée!'),
              backgroundColor: Colors.green,
            ),
          );

          // ✨ AFFICHER LE DIALOGUE D'INVITATION
          if (kDebugMode) debugPrint('⏳ Attente de 500ms avant d\'afficher le dialogue d\'invitation...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            if (kDebugMode) debugPrint('🔔 Affichage du dialogue d\'invitation');
            _showInvitationDialog();
          }
        }
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _declineEvent() async {
    if (widget.currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await _registrationService.declineEvent(
        widget.event.id,
        widget.currentUser!.uid,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rencontre refusée'),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelDecline() async {
    if (widget.currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await _registrationService.cancelDecline(
        widget.event.id,
        widget.currentUser!.uid,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refus annulé'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCollationSelection() async {
    if (widget.currentUser == null) return;

    final participates = await showCollationDialog(
      context,
      event: widget.event,
      currentUserId: widget.currentUser!.uid,
    );

    if (participates == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _registrationService.saveCollationChoice(
        widget.event.id,
        widget.currentUser!.uid,
        participates,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(participates
                ? 'Participation au repas enregistrée !'
                : 'Vous ne participez pas au repas'),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _openLocation() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ouverture de Google Maps...'),
          duration: Duration(seconds: 1),
        ),
      );
      await LocationService.openMaps(widget.event.lieu);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: Impossible d\'ouvrir Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showInvitationDialog() async {
    if (widget.currentUser == null) {
      if (kDebugMode) debugPrint('❌ Erreur: Pas d\'utilisateur connecté');
      return;
    }
    if (kDebugMode) debugPrint('📨 Ouverture du dialogue d\'invitation...');
    final invitations = await showInvitationDialog(
      context,
      eventId: widget.event.id,
      currentUserId: widget.currentUser!.uid,
    );

    if (kDebugMode) debugPrint('💬 Invitations retournées: $invitations');
    if (invitations != null && invitations.isNotEmpty && mounted) {
      if (kDebugMode) debugPrint('✅ Envoi des invitations...');
      _sendInvitations(invitations);
    } else {
      if (kDebugMode) debugPrint('⚠️ Aucune invitation à envoyer ou dialogue fermé');
    }
  }

Future<void> _sendInvitations(List<Map<String, String>> invitations) async {
    if (kDebugMode) debugPrint('🚀 Envoi de ${invitations.length} invitation(s)...');
    try {
      // ✅ Utiliser createInvitationsWithUsers qui:
      //    • Crée l'utilisateur avec email et rôle "invite"
      //    • Crée l'invitation liée
      //    • NE FAIT PAS d'envoi de mail
      await _invitationService.createInvitationsWithUsers(
        eventId: widget.event.id,
        invitedByUserId: widget.currentUser!.uid,
        invitations: invitations, // ✅ Contient: email, prenom, nom
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${invitations.length} invitation(s) envoyée(s) avec succès!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (kDebugMode) debugPrint('✅ Invitations créées avec succès (emails sauvegardés)!');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur lors de l\'envoi: $e');
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


  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _elevation,
        builder: (context, child) {
          return Card(
            elevation: _elevation.value,
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.isDark 
                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                  : Colors.grey[200]!,
                width: 1,
              ),
            ),
            color: widget.isDark 
              ? Colors.grey[900]?.withValues(alpha: 0.6)
              : Colors.white,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: widget.event.isFinished
                    ? _buildFinishedView()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isUserDeclined
                              ? _buildDeclinedView()
                              : _isUserConfirmed
                                  ? _buildConfirmedView()
                                  : _isUserInscribed
                                      ? _buildInscribedView()
                                      : _buildUnregisteredView(),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ========================================
  // ÉTAT: TERMINÉ — vue simplifiée
  // ========================================
  Widget _buildFinishedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventImage(),
        // Date
        Text(
          widget.event.formattedDate,
          style: TextStyle(
            fontSize: 12,
            color: widget.isDark ? Colors.grey[400] : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        // Titre
        Text(
          widget.event.theme,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Badge "Terminé"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Terminé',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        // Compte-rendu
        if (widget.event.hasSummary) _buildSummarySection(),
      ],
    );
  }

  // ========================================
  // ÉTAT 1: NON INSCRIT
  // ========================================
  Widget _buildUnregisteredView() {
    final canRegister = !widget.event.isStarted && !widget.event.isFull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventImage(),
        // En-tête
        Text(
          widget.event.formattedDate,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(
                color: Colors.blue[400],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.event.theme,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 20),

        // Détails
        _buildDetailRow(
          context,
          Icons.person_outline,
          'Intervenant',
          widget.event.intervenant,
          isDefined: widget.event.isDefinedIntervenant,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          Icons.business_outlined,
          'Entreprise',
          widget.event.entreprise,
          isDefined: widget.event.isDefinedEntreprise,
        ),
        const SizedBox(height: 12),
        _buildLocationRow(
          context,
          widget.event.lieu,
          isDefined: widget.event.isDefinedLieu,
        ),

        const SizedBox(height: 16),

        // Message si inscriptions fermées
        if (widget.event.isStarted)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange[900]?.withValues(alpha: 0.2),
              border: Border.all(color: Colors.orange[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, size: 18, color: Colors.orange[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les inscriptions sont fermées',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Boutons S'inscrire + Refuser
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: (!canRegister || _isLoading) ? null : _toggleRegistration,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'En cours...' : 'je viens'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[600],
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.event.isStarted) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _declineEvent,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('je ne viens pas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ========================================
  // ÉTAT 2: REFUSÉ
  // ========================================
  Widget _buildDeclinedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventImage(),
        // Date + badge "Refusé"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.event.formattedDate,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.red[900]?.withValues(alpha: 0.3)
                    : Colors.red[50],
                border: Border.all(color: Colors.red[400]!, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel, size: 14, color: Colors.red[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Refusé',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[400],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Titre
        Text(
          widget.event.theme,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        // Bouton Annuler (pleine largeur, hauteur 44)
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _cancelDecline,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.undo),
            label: const Text('Annuler le refus'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[500]!),
              foregroundColor: Colors.grey[500],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // ÉTAT 3: INSCRIT - AVANT LE DÉBUT
  // ========================================
  Widget _buildInscribedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventImage(),
        // En-tête avec badge selon état
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.formattedDate,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          color: Colors.blue[400],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.theme,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Badge "En attente" ou "À confirmer"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.event.isStarted
                    ? (widget.isDark ? Colors.purple[900]?.withValues(alpha: 0.3) : Colors.purple[50])
                    : (widget.isDark ? Colors.orange[900]?.withValues(alpha: 0.3) : Colors.orange[50]),
                border: Border.all(
                  color: widget.event.isStarted
                      ? Colors.purple[400]!
                      : Colors.orange[400]!,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.event.isStarted ? Icons.check_circle : Icons.schedule,
                    size: 16,
                    color: widget.event.isStarted
                        ? Colors.purple[400]
                        : Colors.orange[400],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Je suis inscrit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.event.isStarted
                          ? Colors.purple[300]
                          : Colors.orange[300],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lieu
        _buildLocationRow(
          context,
          widget.event.lieu,
          isDefined: widget.event.isDefinedLieu,
        ),
        const SizedBox(height: 16),

        // Boutons selon l'état de l'événement
        if (!widget.event.isStarted)
          // Mode avant le début - bouton d'invitation
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _showInvitationDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('📨 Inviter quelqu\'un'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // Bouton collation (si disponible)
        if (widget.event.hasCollation && widget.currentUser != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _showCollationSelection,
              icon: Icon(
                widget.event.hasUserChosenCollation(widget.currentUser!.uid)
                    ? Icons.restaurant
                    : Icons.restaurant_menu,
              ),
              label: Text(
                widget.event.hasUserChosenCollation(widget.currentUser!.uid)
                    ? 'Modifier ma réponse au repas'
                    : 'Répondre pour le repas',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber[700],
                side: BorderSide(color: Colors.amber[700]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ========================================
  // ÉTAT 4: CONFIRMÉ
  // ========================================
  Widget _buildConfirmedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventImage(),
        // En-tête avec badge "Présent ✅"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.formattedDate,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          color: Colors.blue[400],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.theme,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Badge "Présent ✅" (vert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.orange[900]?.withValues(alpha: 0.3) : Colors.orange[50],
                border: Border.all(
                  color: Colors.orange[400]!,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.orange[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Présent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[300],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lieu
        _buildLocationRow(
          context,
          widget.event.lieu,
          isDefined: widget.event.isDefinedLieu,
        ),
        const SizedBox(height: 16),

        // Message de confirmation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[900]?.withValues(alpha: 0.2),
            border: Border.all(color: Colors.green[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: Colors.green[400]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Votre présence est confirmée',
                  style: TextStyle(
                    color: Colors.green[300],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bandeau collation si choix effectué
        if (widget.event.hasCollation && widget.currentUser != null &&
            widget.event.hasUserChosenCollation(widget.currentUser!.uid)) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.orange[900]?.withValues(alpha: 0.3) : Colors.orange[50],
              border: Border.all(color: Colors.orange[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant, size: 18, color: Colors.orange[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Repas réservé',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ========================================
  // WIDGETS HELPERS
  // ========================================

  Widget _buildEventImage() {
    if (widget.event.imageUrl == null || widget.event.imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.event.imageUrl!,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ========================================
  // COMPTE-RENDU (événement terminé)
  // ========================================
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(color: widget.isDark ? Colors.grey[700] : Colors.grey[300]),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSummaryBottomSheet(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.teal[900]?.withValues(alpha: 0.3)
                  : Colors.teal[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isDark ? Colors.teal[700]! : Colors.teal[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.summarize_outlined, size: 18, color: Colors.teal[600]),
                const SizedBox(width: 8),
                Text(
                  'Voir le compte-rendu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.teal[300] : Colors.teal[700],
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 18, color: Colors.teal[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSummaryBottomSheet() {
    final isDark = widget.isDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.summarize_outlined, color: Colors.teal[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.event.theme,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Compte-rendu de la rencontre',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
              const SizedBox(height: 12),
              MarkdownBody(
                data: widget.event.summary!,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    required bool isDefined,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDefined ? Colors.blue[400] : Colors.orange[300],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDefined
                      ? (widget.isDark ? Colors.grey[100] : Colors.grey[900])
                      : Colors.orange[300],
                  fontWeight: isDefined ? FontWeight.w500 : FontWeight.w400,
                  fontStyle: isDefined ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    String value, {
    required bool isDefined,
  }) {
    return GestureDetector(
      onTap: isDefined ? _openLocation : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: isDefined ? Colors.blue[400] : Colors.orange[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lieu',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDefined
                        ? (widget.isDark ? Colors.grey[100] : Colors.grey[900])
                        : Colors.orange[300],
                    fontWeight: isDefined ? FontWeight.w500 : FontWeight.w400,
                    fontStyle: isDefined ? FontStyle.normal : FontStyle.italic,
                    decoration: isDefined ? TextDecoration.underline : null,
                    decorationColor: Colors.blue[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDefined)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '🔗 Cliquer pour ouvrir Maps',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue[400],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      setState(() {});
    }
    if (oldWidget.currentUser?.uid != widget.currentUser?.uid ||
        oldWidget.event.id != widget.event.id) {
      setState(() {});
    }
  }
}