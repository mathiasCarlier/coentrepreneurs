// widgets/invitation_dialog.dart - VERSION SÉCURISÉE

import 'package:flutter/material.dart';

class InvitationDialog extends StatefulWidget {
  final String eventId;
  final String currentUserId;
  final VoidCallback onInvitationSent;

  const InvitationDialog({
    super.key,
    required this.eventId,
    required this.currentUserId,
    required this.onInvitationSent,
  });

  @override
  State<InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<InvitationDialog> {
  late TextEditingController _emailController;
  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _prenomController = TextEditingController();
    _nomController = TextEditingController();
    
    // 🔍 VÉRIFICATIONS DE SÉCURITÉ
    print('✅ InvitationDialog initialisé');
    print('   - Event ID: "${widget.eventId}"');
    print('   - User ID: "${widget.currentUserId}"');
    print('   - Event ID vide? ${widget.eventId.isEmpty}');
    print('   - User ID vide? ${widget.currentUserId.isEmpty}');
    
    // Si l'ID est vide, afficher une erreur immédiatement
    if (widget.eventId.isEmpty || widget.currentUserId.isEmpty) {
      print('❌ ERREUR: IDs vides!');
      setState(() {
        _error = 'Erreur: Les paramètres de l\'événement ne sont pas valides. '
                 'EventID: "${widget.eventId}", UserID: "${widget.currentUserId}"';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  void _submitInvitations() {
    print('🚀 _submitInvitations appelée');
    
    // 🔍 VÉRIFIER LES PARAMÈTRES D'ABORD
    if (widget.eventId.isEmpty || widget.currentUserId.isEmpty) {
      print('❌ ERREUR: IDs vides à la soumission!');
      setState(() {
        _error = 'ERREUR CRITIQUE: Les IDs sont vides. '
                 'Impossible de créer l\'invitation. '
                 'Veuillez réessayer.';
      });
      return;
    }

    // Réinitialiser l'erreur
    setState(() {
      _error = null;
    });

    // Valider que au moins un champ email est rempli
    if (_emailController.text.isEmpty) {
      print('❌ Email vide');
      setState(() {
        _error = 'Veuillez entrer un email';
      });
      return;
    }

    // Valider l'email
    if (!_isValidEmail(_emailController.text.trim())) {
      print('❌ Email invalide: ${_emailController.text}');
      setState(() {
        _error = 'Email invalide (ex: jean@email.com)';
      });
      return;
    }

    // Valider prénom
    if (_prenomController.text.trim().isEmpty) {
      print('❌ Prénom vide');
      setState(() {
        _error = 'Veuillez entrer un prénom';
      });
      return;
    }

    // Valider nom
    if (_nomController.text.trim().isEmpty) {
      print('❌ Nom vide');
      setState(() {
        _error = 'Veuillez entrer un nom';
      });
      return;
    }

    // Créer la liste d'invitations
    List<Map<String, String>> invitations = [
      {
        'email': _emailController.text.trim().toLowerCase(),
        'prenom': _prenomController.text.trim(),
        'nom': _nomController.text.trim(),
      }
    ];

    print('✅ Invitation valide:');
    print('   - Email: ${invitations[0]['email']}');
    print('   - Prénom: ${invitations[0]['prenom']}');
    print('   - Nom: ${invitations[0]['nom']}');
    print('   - Event ID: ${widget.eventId}');
    print('   - User ID: ${widget.currentUserId}');
    
    print('🔄 Fermeture du dialogue et retour des données');
    
    // Retourner les invitations et fermer le dialogue
    Navigator.of(context).pop(invitations);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    print('🎨 Construction du dialogue d\'invitation');

    // 🔴 SI LES IDS SONT VIDES, AFFICHER UNE ERREUR ET BLOQUER
    if (widget.eventId.isEmpty || widget.currentUserId.isEmpty) {
      return Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '❌ Erreur',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Erreur critique',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Les IDs de l\'événement ou de l\'utilisateur sont vides.',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Détails:',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Event ID: "${widget.eventId}" (vide: ${widget.eventId.isEmpty})',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• User ID: "${widget.currentUserId}" (vide: ${widget.currentUserId.isEmpty})',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Veuillez fermer ce dialogue et réessayer.',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 🟢 DIALOGUE NORMAL SI LES IDS SONT VALIDES
    return WillPopScope(
      onWillPop: () async {
        print('👈 Fermeture du dialogue (bouton retour)');
        return true;
      },
      child: Dialog(
        insetAnimationDuration: const Duration(milliseconds: 300),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EN-TÊTE
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '📨 Inviter quelqu\'un',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            print('❌ Fermeture du dialogue');
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close),
                          tooltip: 'Fermer',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remplissez les informations de la personne à inviter',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),

              // CONTENU PRINCIPAL
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message d'erreur
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(color: Colors.red, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Erreur',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() => _error = null);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                      // Titre du formulaire
                      Text(
                        'Informations requises',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          hintText: 'exemple@email.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          if (_error != null) {
                            setState(() => _error = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Prénom et Nom (Row)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _prenomController,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: 'Prénom *',
                                hintText: 'Jean',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              onChanged: (value) {
                                if (_error != null) {
                                  setState(() => _error = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _nomController,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: 'Nom *',
                                hintText: 'Dupont',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                if (_error != null) {
                                  setState(() => _error = null);
                                }
                              },
                              onSubmitted: (value) {
                                if (!_isLoading) {
                                  _submitInvitations();
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.blue[400]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info, color: Colors.blue[400], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comment ça marche?',
                                    style: TextStyle(
                                      color: Colors.blue[400],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Une invitation sera envoyée à cette personne.',
                                    style: TextStyle(
                                      color: Colors.blue[400],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),

              // BOUTONS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              print('❌ Annulation');
                              Navigator.of(context).pop();
                            },
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitInvitations,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? 'Envoi...' : 'Inviter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Fonction helper ROBUSTE pour afficher le dialogue
Future<List<Map<String, String>>?> showInvitationDialog(
  BuildContext context, {
  required String eventId,
  required String currentUserId,
}) async {
  print('📱 Ouverture du dialogue d\'invitation');
  print('   - Event ID: "$eventId" (vide: ${eventId.isEmpty})');
  print('   - User ID: "$currentUserId" (vide: ${currentUserId.isEmpty})');

  // 🔴 VÉRIFICATION CRITIQUE
  if (eventId.isEmpty || currentUserId.isEmpty) {
    print('❌ ERREUR CRITIQUE: IDs vides!');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Erreur: Les données de l\'événement ne sont pas valides'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    return null;
  }

  try {
    final result = await showDialog<List<Map<String, String>>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        print('🔨 Construction du widget InvitationDialog');
        return InvitationDialog(
          eventId: eventId,
          currentUserId: currentUserId,
          onInvitationSent: () {
            print('✅ Callback onInvitationSent');
          },
        );
      },
    );

    print('📊 Résultat du dialogue: $result');
    return result;
  } catch (e) {
    print('❌ ERREUR dans showInvitationDialog: $e');
    print('   Stack trace: ${StackTrace.current}');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur du dialogue: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    return null;
  }
}