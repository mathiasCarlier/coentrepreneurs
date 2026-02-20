// widgets/feedback_prompt.dart
// Version CORRIGÉE - Compatible Web + Mobile

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
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
    print('🔍 FeedbackPrompt initié pour événement: ${widget.event.id}');
    print('   Status: ${widget.event.status}');
    // Utiliser addPostFrameCallback pour s'assurer que le context est disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowFeedback();
    });
  }

  Future<void> _checkAndShowFeedback() async {
    print('📋 Vérification des conditions du feedback...');

    // 1️⃣ Vérifier que l'événement est TERMINÉ
    print('   1️⃣ Status événement: ${widget.event.status}');
    if (widget.event.status != EventStatus.finished) {
      print('   ❌ Événement pas terminé - Status: ${widget.event.status}');
      return;
    }
    print('   ✅ Événement terminé');

    // 2️⃣ Récupérer l'utilisateur actuel via Firebase Auth
    final currentFirebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentFirebaseUser == null) {
      print('   ❌ Utilisateur non connecté');
      return;
    }
    print('   ✅ Utilisateur connecté: ${currentFirebaseUser.email}');

    // 3️⃣ Récupérer les infos complètes de l'utilisateur depuis Firestore
    user_model.User? currentUser;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentFirebaseUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        currentUser = user_model.User(
          uid: currentFirebaseUser.uid,
          email: data['email'] ?? currentFirebaseUser.email ?? '',
          nom: data['nom'] ?? 'Inconnu',
          prenom: data['prenom'] ?? '',
          role: _stringToUserRole(data['role'] ?? 'adherent'),
          phone: data['telephone'],
        );
        print('   ✅ Utilisateur trouvé: ${currentUser.prenom} ${currentUser.nom}');
      }
    } catch (e) {
      print('   ❌ Erreur lors de la récupération utilisateur: $e');
      return;
    }

    if (currentUser == null) {
      print('   ❌ Utilisateur null');
      return;
    }

    // 4️⃣ Vérifier que l'utilisateur est UN PARTICIPANT CONFIRMÉ
    print('   4️⃣ Vérification si confirmé...');
    print('      Participants confirmés: ${widget.event.confirmedParticipants}');
    print('      User UID: ${currentUser.uid}');

    if (!widget.event.confirmedParticipants.contains(currentUser.uid)) {
      print('   ❌ Utilisateur pas confirmé');
      return;
    }
    print('   ✅ Utilisateur confirmé');

    // 5️⃣ Vérifier qu'un feedback n'a pas déjà été donné
    print('   5️⃣ Vérification si feedback existe déjà...');
    try {
      final hasFeedback = await _feedbackService.hasFeedback(
        widget.event.id,
        currentUser.uid,
      );

      if (hasFeedback) {
        print('   ℹ️ Feedback déjà donné');
        return;
      }
      print('   ✅ Aucun feedback existant');
    } catch (e) {
      print('   ❌ Erreur lors de la vérification: $e');
      return;
    }

    // 6️⃣ Afficher le formulaire
    print('✨ Affichage du formulaire de feedback');
    if (mounted && !_feedbackShown) {
      _feedbackShown = true;
      _showFeedbackDialog(currentUser);
    }
  }

  void _showFeedbackDialog(user_model.User currentUser) {
    print('📢 Affichage du dialog');
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
          print('✅ Feedback soumis');
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