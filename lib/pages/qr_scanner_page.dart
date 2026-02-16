// pages/qr_scanner_page.dart - CONFIRMATION DE PRÉSENCE
import 'package:flutter/material.dart';
import 'package:coentrepreneurs/services/event_service.dart';

class ConfirmPresencePage extends StatefulWidget {
  final String eventId;
  final String userId;

  const ConfirmPresencePage({
    super.key,
    required this.eventId,
    required this.userId,
  });

  @override
  State<ConfirmPresencePage> createState() => _ConfirmPresencePageState();
}

class _ConfirmPresencePageState extends State<ConfirmPresencePage> {
  final EventService _eventService = EventService();
  bool _isProcessing = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _confirmPresence() async {
    setState(() => _isProcessing = true);

    try {
      await _eventService.confirmParticipation(
        widget.eventId,
        widget.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Présence confirmée!'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmer votre présence'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.event_available,
                  size: 80,
                  color: Colors.blue[400],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Êtes-vous présent?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Confirmez votre présence à cet événement.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _confirmPresence,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isProcessing ? 'Confirmation...' : 'Confirmer ma présence',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
