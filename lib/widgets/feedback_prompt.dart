// widgets/feedback_prompt.dart
// Version CORRIGÉE - Compatible Web + Mobile

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;
import 'package:coentrepreneurs/services/feedback_service.dart';
import 'package:coentrepreneurs/widgets/feedback_dialog.dart';

class FeedbackPrompt extends StatefulWidget {
  final Event event;

  const FeedbackPrompt({
    super.key,
    required this.event,
  });

  @override
  State<FeedbackPrompt> createState() => _FeedbackPromptState();
}

class _FeedbackPromptState extends State<FeedbackPrompt> {
  final FeedbackService _feedbackService = FeedbackService();
  bool _feedbackShown = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 FeedbackPrompt initié pour événement: ${widget.event.id}');
    debugPrint('   Status: ${widget.event.status}');
    // Utiliser addPostFrameCallback pour s'assurer que le context est disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowFeedback();
    });
  }

  @override
  void didUpdateWidget(FeedbackPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Détecter le passage en statut "finished" en temps réel (ex: admin termine la rencontre)
    if (!_feedbackShown &&
        oldWidget.event.status != EventStatus.finished &&
        widget.event.status == EventStatus.finished) {
      debugPrint('🔄 Statut passé à finished - vérification du feedback');
      _checkAndShowFeedback();
    }
  }

  Future<void> _checkAndShowFeedback() async {
    debugPrint('📋 Vérification des conditions du feedback...');

    // 1️⃣ Vérifier que l'événement est TERMINÉ
    debugPrint('   1️⃣ Status événement: ${widget.event.status}');
    if (widget.event.status != EventStatus.finished) {
      debugPrint('   ❌ Événement pas terminé - Status: ${widget.event.status}');
      return;
    }
    debugPrint('   ✅ Événement terminé');

    // 2️⃣ Récupérer l'utilisateur actuel via Supabase Auth
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser == null) {
      debugPrint('   ❌ Utilisateur non connecté');
      return;
    }
    debugPrint('   ✅ Utilisateur connecté: ${supabaseUser.email}');

    // 3️⃣ Récupérer les infos complètes de l'utilisateur depuis la table users
    user_model.User? currentUser;
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle();

      if (data != null) {
        currentUser = user_model.User(
          uid: supabaseUser.id,
          email: data['email'] ?? supabaseUser.email ?? '',
          nom: data['nom'] ?? 'Inconnu',
          prenom: data['prenom'] ?? '',
          role: _stringToUserRole(data['role'] ?? 'adherent'),
          phone: data['phone'],
        );
        debugPrint('   ✅ Utilisateur trouvé: ${currentUser.prenom} ${currentUser.nom}');
      }
    } catch (e) {
      debugPrint('   ❌ Erreur lors de la récupération utilisateur: $e');
      return;
    }

    if (currentUser == null) {
      debugPrint('   ❌ Utilisateur null');
      return;
    }

    // 4️⃣ Vérifier que l'utilisateur est UN PARTICIPANT CONFIRMÉ
    debugPrint('   4️⃣ Vérification si confirmé...');
    debugPrint('      Participants confirmés: ${widget.event.confirmedParticipants}');
    debugPrint('      User UID: ${currentUser.uid}');

    if (!widget.event.confirmedParticipants.contains(currentUser.uid)) {
      debugPrint('   ❌ Utilisateur pas confirmé');
      return;
    }
    debugPrint('   ✅ Utilisateur confirmé');

    // 5️⃣ Vérifier qu'un feedback n'a pas déjà été donné
    debugPrint('   5️⃣ Vérification si feedback existe déjà...');
    try {
      final hasFeedback = await _feedbackService.hasFeedback(
        widget.event.id,
        currentUser.uid,
      );

      if (hasFeedback) {
        debugPrint('   ℹ️ Feedback déjà donné');
        return;
      }
        debugPrint('   ✅ Aucun feedback existant');
    } catch (e) {
      debugPrint('   ❌ Erreur lors de la vérification: $e');
      return;
    }

    // 6️⃣ Afficher le formulaire
    debugPrint('✨ Affichage du formulaire de feedback');
    if (mounted && !_feedbackShown) {
      _feedbackShown = true;
      _showFeedbackDialog(currentUser);
    }
  }

  void _showFeedbackDialog(user_model.User currentUser) {
    debugPrint('📢 Affichage du dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FeedbackDialog(
        eventId: widget.event.id,
        userId: currentUser.uid,
        userEmail: currentUser.email,
        userPrenom: currentUser.prenom,
        userNom: currentUser.nom,
        onSubmitted: () {
          debugPrint('✅ Feedback soumis');
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  user_model.UserRole _stringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return user_model.UserRole.admin;
      case 'invite':
        return user_model.UserRole.invite;
      default:
        return user_model.UserRole.adherent;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ce widget est invisible, il sert juste à déclencher le formulaire
    return const SizedBox.shrink();
  }
}