// widgets/invitation_dialog.dart

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
  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController();
    _nomController = TextEditingController();

    if (widget.eventId.isEmpty || widget.currentUserId.isEmpty) {
      setState(() {
        _error = 'Erreur: Les paramètres de l\'événement ne sont pas valides.';
      });
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  void _submitInvitations() {
    if (widget.eventId.isEmpty || widget.currentUserId.isEmpty) {
      setState(() {
        _error = 'ERREUR CRITIQUE: Les IDs sont vides. Veuillez réessayer.';
      });
      return;
    }

    setState(() => _error = null);

    if (_prenomController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer un prénom');
      return;
    }

    if (_nomController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer un nom');
      return;
    }

    List<Map<String, String>> invitations = [
      {
        'prenom': _prenomController.text.trim(),
        'nom': _nomController.text.trim(),
      }
    ];

    Navigator.of(context).pop(invitations);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('❌ Erreur',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Les IDs de l\'événement ou de l\'utilisateur sont vides.',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Fermer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => true,
      child: Dialog(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👤 Inviter quelqu\'un',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Entrez le prénom et le nom de l\'invité',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),

              // CONTENU
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Erreur
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
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _error = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                      // Prénom + Nom
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
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_error != null) setState(() => _error = null);
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
                                    borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              textInputAction: TextInputAction.done,
                              onChanged: (_) {
                                if (_error != null) setState(() => _error = null);
                              },
                              onSubmitted: (_) {
                                if (!_isLoading) _submitInvitations();
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
                          border: Border.all(color: Colors.blue[400]!, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[400], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'L\'invité apparaîtra dans la liste des participants de l\'événement.',
                                style: TextStyle(color: Colors.blue[400], fontSize: 11),
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
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(_isLoading ? 'Ajout...' : 'Inviter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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

// Fonction helper
Future<List<Map<String, String>>?> showInvitationDialog(
  BuildContext context, {
  required String eventId,
  required String currentUserId,
}) async {
  if (eventId.isEmpty || currentUserId.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur: Les données de l\'événement ne sont pas valides'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
    return null;
  }

  try {
    return await showDialog<List<Map<String, String>>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => InvitationDialog(
        eventId: eventId,
        currentUserId: currentUserId,
        onInvitationSent: () {},
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }
}