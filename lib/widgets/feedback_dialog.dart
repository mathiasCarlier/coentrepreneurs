// widgets/feedback_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:coentrepreneurs/models/feedback.dart' as fb_model;
import 'package:coentrepreneurs/services/feedback_service.dart';

class FeedbackDialog extends StatefulWidget {
  final String eventId;
  final String userId;
  final String userEmail;
  final String userPrenom;
  final String userNom;
  final VoidCallback onSubmitted;

  const FeedbackDialog({
    super.key,
    required this.eventId,
    required this.userId,
    required this.userEmail,
    required this.userPrenom,
    required this.userNom,
    required this.onSubmitted,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final FeedbackService _feedbackService = FeedbackService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _whatYouLikedController;
  late TextEditingController _whatYouLearnedController;
  int _rating = 5;
  bool _isLoading = false;
  String? _error;
  fb_model.Feedback? _existingFeedback;

  @override
  void initState() {
    super.initState();
    _whatYouLikedController = TextEditingController();
    _whatYouLearnedController = TextEditingController();
    _loadExistingFeedback();
  }

  @override
  void dispose() {
    _whatYouLikedController.dispose();
    _whatYouLearnedController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFeedback() async {
    try {
      final feedback = await _feedbackService.getUserEventFeedback(
        widget.eventId,
        widget.userId,
      );
      
      if (feedback != null && mounted) {
        setState(() {
          _existingFeedback = feedback;
          _whatYouLikedController.text = feedback.whatYouLiked;
          _rating = feedback.rating;
          _whatYouLearnedController.text = feedback.whatYouLearned;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors du chargement du feedback existant: $e');
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_existingFeedback != null) {
        // Mise à jour du feedback existant
        await _feedbackService.updateFeedback(
          feedbackId: _existingFeedback!.id,
          whatYouLiked: _whatYouLikedController.text.trim(),
          rating: _rating,
          whatYouLearned: _whatYouLearnedController.text.trim(),
        );
      } else {
        // Créer un nouveau feedback
        await _feedbackService.createFeedback(
          eventId: widget.eventId,
          userId: widget.userId,
          userEmail: widget.userEmail,
          userPrenom: widget.userPrenom,
          userNom: widget.userNom,
          whatYouLiked: _whatYouLikedController.text.trim(),
          rating: _rating,
          whatYouLearned: _whatYouLearnedController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Merci pour votre feedback!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
        widget.onSubmitted();
      }
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
      if (kDebugMode) debugPrint('Erreur lors de la soumission du feedback: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existingFeedback != null ? 'Mettre à jour le feedback' : 'Votre avis sur la rencontre',
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isLoading
                    ? 'Envoi...'
                    : _existingFeedback != null
                        ? 'Mettre à jour'
                        : 'Envoyer',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  const SizedBox(height: 8),

                  // Question 1: Qu'est-ce qui vous a plu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Qu\'est-ce qui vous a plu dans la rencontre?',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' *',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _whatYouLikedController,
                        enabled: !_isLoading,
                        maxLines: 4,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Partagez ce qui vous a plu...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Cette question est obligatoire';
                          }
                          if (value.trim().length < 10) {
                            return 'Veuillez écrire au moins 10 caractères';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Question 2: Note de 0 à 10
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Donnez une note de 0 à 10 à cette rencontre',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' *',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          // Slider avec affichage de la note
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRatingColor(_rating).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getRatingColor(_rating),
                                    ),
                                  ),
                                  child: Text(
                                    _rating.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getRatingColor(_rating),
                                    ),
                                  ),
                                ),
                                const Text(
                                  '10',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: _rating.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            label: _rating.toString(),
                            activeColor: _getRatingColor(_rating),
                            inactiveColor: isDark ? Colors.grey[700] : Colors.grey[300],
                            onChanged: _isLoading ? null : (value) {
                              setState(() => _rating = value.toInt());
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _RatingLabel(label: 'Très mauvais', value: 0, currentRating: _rating),
                              _RatingLabel(label: 'Mauvais', value: 2, currentRating: _rating),
                              _RatingLabel(label: 'Neutre', value: 5, currentRating: _rating),
                              _RatingLabel(label: 'Bon', value: 7, currentRating: _rating),
                              _RatingLabel(label: 'Excellent', value: 10, currentRating: _rating),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Question 3: Ce que vous avez retenu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Qu\'est-ce que tu as retenu de cette rencontre?',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' *',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _whatYouLearnedController,
                        enabled: !_isLoading,
                        maxLines: 4,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Partagez les apprentissages clés...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Cette question est obligatoire';
                          }
                          if (value.trim().length < 10) {
                            return 'Veuillez écrire au moins 10 caractères';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  // Message d'erreur
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (_isLoading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        );
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating <= 5) return Colors.orange;
    if (rating <= 7) return Colors.yellow[700]!;
    if (rating <= 9) return Colors.lightGreen;
    return Colors.green;
  }
}

// Widget pour afficher les labels des notes
class _RatingLabel extends StatelessWidget {
  final String label;
  final int value;
  final int currentRating;

  const _RatingLabel({
    required this.label,
    required this.value,
    required this.currentRating,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRating == value;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.blue : Colors.grey,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 50,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: isActive ? Colors.blue : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
