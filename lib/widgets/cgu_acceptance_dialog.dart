// widgets/cgu_acceptance_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:coentrepreneurs/services/cgu_service.dart';

class CGUAcceptanceDialog extends StatefulWidget {
  final VoidCallback onAccepted;
  final bool alreadyAccepted;
  final String? userId;

  const CGUAcceptanceDialog({
    super.key,
    required this.onAccepted,
    this.alreadyAccepted = false,
    this.userId,
  });

  @override
  State<CGUAcceptanceDialog> createState() => _CGUAcceptanceDialogState();
}

class _CGUAcceptanceDialogState extends State<CGUAcceptanceDialog> {
  bool _hasReadCGU = false;
  bool _acceptsCGU = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollPercentage = 0.0;
  final CGUService _cguService = CGUService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollPercentage);
    // Si déjà accepté, on considère que c'est lu
    if (widget.alreadyAccepted) {
      _hasReadCGU = true;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollPercentage);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollPercentage() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll == 0) {
      setState(() => _hasReadCGU = true);
      return;
    }

    final scrollPercentage = (_scrollController.offset / maxScroll) * 100;
    setState(() {
      _scrollPercentage = scrollPercentage;
      // Considérer que l'utilisateur a lu s'il a scrollé jusqu'à 90%
      _hasReadCGU = scrollPercentage >= 90;
    });
  }

  // NOTE: _updateScrollPercentage
  // - Écoute le ScrollController pour calculer le pourcentage de lecture.
  // - Si l'utilisateur a fait défiler >= 90%, `_hasReadCGU` devient true
  //   et active la checkbox d'acceptation.
  // - Important: éviter les setState trop fréquents; ici on met à jour la
  //   valeur à chaque écoute mais le coût est faible (valeur simple).

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      // ✅ Le dialog lui-même est scrollable
      child: SingleChildScrollView(
        child: Container(
          width: screenWidth > 800 ? 600 : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Conditions d\'utilisation',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                      ),
                    ),
                    if (!widget.alreadyAccepted)
                      Tooltip(
                        message: 'Veuillez lire l\'intégralité du document',
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      )
                    else
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.alreadyAccepted
                      ? 'Vous avez déjà accepté les conditions d\'utilisation'
                      : 'Vous devez accepter les conditions d\'utilisation pour accéder à l\'application',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                ),
              ),
              const SizedBox(height: 20),

              // CGU Content with scroll - CONSTRAINED HEIGHT
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: BoxConstraints(
                  maxHeight: isMobile ? 300 : 400,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.grey[900]?.withValues(alpha: 0.3) : Colors.grey[50],
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      // Le contenu des CGU est dans ce scroll; le controller
                      // permet de déterminer si l'utilisateur a réellement
                      // parcouru l'intégralité du texte avant d'autoriser
                      // l'acceptation.
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          CGUService.cguContent,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                height: 1.6,
                                // ✅ TEXTE BLANC - Très visible
                                color: isDark
                                    ? Colors.grey[100]  // Blanc cassé très clair
                                    : Colors.grey[900],  // Noir en mode clair
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ),
                    // Progress indicator en bas (seulement si pas déjà accepté)
                    if (!widget.alreadyAccepted && _scrollPercentage < 100)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: LinearProgressIndicator(
                              value: _scrollPercentage / 100,
                              minHeight: 4,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Progress message (seulement si pas déjà accepté)
              if (!widget.alreadyAccepted)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _hasReadCGU
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Merci de lire les conditions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            border: Border.all(color: Colors.amber.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Veuillez lire entièrement les conditions (${_scrollPercentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

              const SizedBox(height: 20),

              // Checkbox (seulement si pas déjà accepté)
              if (!widget.alreadyAccepted)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  // La checkbox est désactivée tant que `_hasReadCGU` est false.
                  // L'utilisateur doit scroller jusqu'au seuil pour pouvoir cocher.
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: _hasReadCGU,
                    value: _acceptsCGU,
                    onChanged: _hasReadCGU
                        ? (value) {
                            setState(() => _acceptsCGU = value ?? false);
                          }
                        : null,
                    title: Text(
                      'J\'accepte les conditions d\'utilisation',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _hasReadCGU
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.grey[600] : Colors.grey[400]),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    checkColor: Colors.white,
                    activeColor: Colors.blue.shade700,
                  ),
                ),

              const SizedBox(height: 24),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: widget.alreadyAccepted
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Retour',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            // Refuser: on ferme le dialog et on renvoie `false` au
                            // caller. Le traitement de la fermeture/refus est géré
                            // par le code appelant via `.then((accepted) { ... })`.
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text(
                              'Refuser',
                              style: TextStyle(
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _acceptsCGU
                                ? () async {
                                    final navigator = Navigator.of(context);
                                    // Sauvegarder via CGUService
                                    if (widget.userId != null) {
                                      try {
                                        await _cguService.acceptCGU(widget.userId!);
                                      } catch (e) {
                                        if (kDebugMode) debugPrint('Erreur lors de la sauvegarde des CGU: $e');
                                      }
                                    }
                                    if (mounted) {
                                      navigator.pop(true);
                                      widget.onAccepted();
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Text(
                                'Accepter',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}