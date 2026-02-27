// widgets/event_feedback_section.dart
// Affiche les statistiques et le résumé des feedbacks pour un événement terminé

import 'package:flutter/material.dart';
import 'package:coentrepreneurs/models/feedback.dart' as fb_model;
import 'package:coentrepreneurs/services/feedback_service.dart';

class EventFeedbackSection extends StatefulWidget {
  final String eventId;
  final bool isDark;

  const EventFeedbackSection({
    super.key,
    required this.eventId,
    required this.isDark,
  });

  @override
  State<EventFeedbackSection> createState() => _EventFeedbackSectionState();
}

class _EventFeedbackSectionState extends State<EventFeedbackSection> {
  final FeedbackService _feedbackService = FeedbackService();
  late Future<List<fb_model.Feedback>> _feedbacksFuture;
  late Future<double> _averageRatingFuture;

  @override
  void initState() {
    super.initState();
    _feedbacksFuture = _feedbackService.getEventFeedbacks(widget.eventId);
    _averageRatingFuture = _feedbackService.getAverageRating(widget.eventId);
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating <= 5) return Colors.orange;
    if (rating <= 7) return Colors.yellow[700]!;
    if (rating <= 9) return Colors.lightGreen;
    return Colors.green;
  }

  String _getRatingLabel(int rating) {
    if (rating <= 2) return 'Très mauvais';
    if (rating <= 5) return 'Mauvais';
    if (rating <= 7) return 'Neutre';
    if (rating <= 9) return 'Bon';
    return 'Excellent';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.feedback_outlined, size: 24, color: Colors.blue[600]),
            const SizedBox(width: 16),
            Text(
              'Retours des participants',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.grey[200] : Colors.grey[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Statistiques générales
        FutureBuilder<double>(
          future: _averageRatingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final averageRating = snapshot.data ?? 0.0;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Note moyenne',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getRatingColor(averageRating.toInt()).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getRatingColor(averageRating.toInt()),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _getRatingColor(averageRating.toInt()),
                              ),
                            ),
                            Text(
                              '/10',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRatingColor(averageRating.toInt()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getRatingLabel(averageRating.toInt()),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getRatingColor(averageRating.toInt()),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                  FutureBuilder<List<fb_model.Feedback>>(
                    future: _feedbacksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 80,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final feedbackCount = snapshot.data?.length ?? 0;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Feedbacks reçus',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              feedbackCount.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            feedbackCount == 1 ? 'réponse' : 'réponses',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // Liste détaillée des feedbacks
        FutureBuilder<List<fb_model.Feedback>>(
          future: _feedbacksFuture,
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
                  'Erreur lors du chargement des feedbacks',
                  style: TextStyle(color: Colors.red[600]),
                ),
              );
            }

            final feedbacks = snapshot.data ?? [];

            if (feedbacks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Aucun feedback pour le moment',
                    style: TextStyle(
                      color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                final feedback = feedbacks[index];
                return _FeedbackCard(
                  feedback: feedback,
                  isDark: widget.isDark,
                  getRatingColor: _getRatingColor,
                  getRatingLabel: _getRatingLabel,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// Widget pour afficher une carte de feedback
class _FeedbackCard extends StatefulWidget {
  final fb_model.Feedback feedback;
  final bool isDark;
  final Color Function(int) getRatingColor;
  final String Function(int) getRatingLabel;

  const _FeedbackCard({
    required this.feedback,
    required this.isDark,
    required this.getRatingColor,
    required this.getRatingLabel,
  });

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          // En-tête de la carte
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.feedback.userPrenom} ${widget.feedback.userNom}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.feedback.userEmail,
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.getRatingColor(widget.feedback.rating).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: widget.getRatingColor(widget.feedback.rating),
                              ),
                            ),
                            child: Text(
                              '${widget.feedback.rating}/10',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.getRatingColor(widget.feedback.rating),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.getRatingLabel(widget.feedback.rating),
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.getRatingColor(widget.feedback.rating),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: widget.isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Contenu détaillé (expandable)
          if (_expanded) ...[
            Divider(height: 1, thickness: 1, color: widget.isDark ? Colors.grey[700] : Colors.grey[300]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Qu'est-ce qui vous a plu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ce qui a plu :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.feedback.whatYouLiked,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Ce qui a été retenu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ce qui a été retenu :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.feedback.whatYouLearned,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Date de soumission
                  Text(
                    'Répondu le ${_formatDate(widget.feedback.createdAt)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isDark ? Colors.grey[500] : Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
