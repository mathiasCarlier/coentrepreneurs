// widgets/invitation_dialog.dart - VERSION CORRIGÉE AVEC EMAIL

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Affiche un dialogue pour inviter des personnes à un événement
/// Retourne : `List<Map<String, String>>` avec email, prenom, nom
Future<List<Map<String, String>>?> showInvitationDialog(
  BuildContext context, {
  required String eventId,
  required String currentUserId,
}) {
  return showDialog<List<Map<String, String>>>(
    context: context,
    builder: (context) => _InvitationDialog(
      eventId: eventId,
      currentUserId: currentUserId,
    ),
  );
}

class _InvitationDialog extends StatefulWidget {
  final String eventId;
  final String currentUserId;

  const _InvitationDialog({
    required this.eventId,
    required this.currentUserId,
  });

  @override
  State<_InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<_InvitationDialog> {
  // ✅ Liste des invités à ajouter
  final List<Map<String, TextEditingController>> _invitees = [];

  // ✅ État pour afficher les invitations existantes
  List<Map<String, dynamic>> _existingInvitations = [];
  bool _loadingExisting = true;

  // ✅ Validation
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingInvitations();
  }

  Future<void> _loadExistingInvitations() async {
    try {
      final data = await Supabase.instance.client
          .from('invitations')
          .select('invited_user_prenom, invited_user_nom, invited_user_email')
          .eq('event_id', widget.eventId)
          .eq('invited_by_user_id', widget.currentUserId);
      setState(() {
        _existingInvitations = List<Map<String, dynamic>>.from(data);
        _loadingExisting = false;
      });
    } catch (_) {
      setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() {
    for (final invitee in _invitees) {
      invitee['email']?.dispose();
      invitee['prenom']?.dispose();
      invitee['nom']?.dispose();
    }
    super.dispose();
  }

  /// Ajoute un champ vide pour une nouvelle invitation
  void _addInviteeField() {
    setState(() {
      _invitees.add({
        'email': TextEditingController(),
        'prenom': TextEditingController(),
        'nom': TextEditingController(),
      });
      _errorMessage = null;
    });
  }

  /// Supprime un champ d'invitation
  void _removeInviteeField(int index) {
    setState(() {
      _invitees[index]['email']?.dispose();
      _invitees[index]['prenom']?.dispose();
      _invitees[index]['nom']?.dispose();
      _invitees.removeAt(index);
      _errorMessage = null;
    });
  }

  /// Valide et retourne les invitations
  void _submitInvitations() {
    // ✅ Valider qu'au moins une personne est invitée
    if (_invitees.isEmpty) {
      setState(() => _errorMessage = 'Ajoutez au moins une personne');
      return;
    }

    final List<Map<String, String>> invitations = [];

    for (int i = 0; i < _invitees.length; i++) {
      final email = _invitees[i]['email']?.text.trim() ?? '';
      final prenom = _invitees[i]['prenom']?.text.trim() ?? '';
      final nom = _invitees[i]['nom']?.text.trim() ?? '';

      // ✅ Valider que TOUS les champs sont remplis
      if (email.isEmpty) {
        setState(() => _errorMessage = 'Email manquant pour la ligne ${i + 1}');
        return;
      }
      if (prenom.isEmpty) {
        setState(() => _errorMessage = 'Prénom manquant pour la ligne ${i + 1}');
        return;
      }
      if (nom.isEmpty) {
        setState(() => _errorMessage = 'Nom manquant pour la ligne ${i + 1}');
        return;
      }

      // ✅ Valider format email
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
        setState(() => _errorMessage = 'Email invalide ligne ${i + 1}');
        return;
      }

      invitations.add({
        'email': email, // ✅ AJOUTÉ
        'prenom': prenom,
        'nom': nom,
      });
    }

    if (kDebugMode) debugPrint('✅ Invitations valides: $invitations');
    Navigator.of(context).pop(invitations);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('📧 Inviter des personnes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ℹ️ Instruction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Remplissez les informations pour inviter des personnes à cet événement.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[900],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📋 Liste des invités
            if (_invitees.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingExisting
                  ? const Center(child: CircularProgressIndicator())
                  : _existingInvitations.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun invité pour le moment',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Déjà invité(s) :',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._existingInvitations.map((inv) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Vous avez invité ${inv['invited_user_prenom']} ${inv['invited_user_nom']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
            )
            else
              Column(
                children: List.generate(_invitees.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Numéro de ligne
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Personne ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _removeInviteeField(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // ✅ Email (OBLIGATOIRE)
                        TextField(
                          controller: _invitees[index]['email'],
                          decoration: InputDecoration(
                            labelText: 'Email *',
                            hintText: 'john@example.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 8),

                        // ✅ Prénom (OBLIGATOIRE)
                        TextField(
                          controller: _invitees[index]['prenom'],
                          decoration: InputDecoration(
                            labelText: 'Prénom *',
                            hintText: 'John',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.person_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ✅ Nom (OBLIGATOIRE)
                        TextField(
                          controller: _invitees[index]['nom'],
                          decoration: InputDecoration(
                            labelText: 'Nom *',
                            hintText: 'Doe',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.person_outlined),
                          ),
                        ),

                        // Séparateur
                        if (index < _invitees.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Divider(
                              color: Colors.grey[300],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),

            const SizedBox(height: 16),

            // 📌 Message d'erreur
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border.all(color: Colors.red[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              )
            else
              const SizedBox(height: 0),

            const SizedBox(height: 16),

            // ➕ Bouton "Ajouter une personne"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addInviteeField,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une personne'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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
          onPressed: _submitInvitations,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          child: const Text('✅ Envoyer les invitations'),
        ),
      ],
    );
  }
}