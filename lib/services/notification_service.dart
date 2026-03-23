// lib/services/notification_service.dart
// Gère l'abonnement aux notifications push navigateur (VAPID, web uniquement).
// Utilise un bridge JavaScript (web/push_utils.js) via dart:js_interop.
//
// IMPORTANT : remplacer _vapidPublicKey par votre clé VAPID publique
// générée avec : npx web-push generate-vapid-keys

import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Clé VAPID publique (à remplacer après génération des clés)
// La clé privée doit rester dans les secrets Supabase uniquement.
// ---------------------------------------------------------------------------
const String _vapidPublicKey = 'BH-mcoCnWW7AxhCyrwqDdqTklAedi8Xzku0wPXLbW1h0wi3PNH9SXiVk-fGGi78fg7a2XDqzNgTrks5hJFesdpU';

// ---------------------------------------------------------------------------
// Bridge JS : appelle window._pushUtils défini dans web/push_utils.js
// ---------------------------------------------------------------------------
@JS('_pushUtils.subscribe')
external JSPromise<JSString> _jsPushSubscribe(JSString vapidKey);

@JS('_pushUtils.unsubscribe')
external JSPromise<JSString> _jsPushUnsubscribe();

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Singleton gérant l'abonnement push navigateur.
///
/// Usage :
///   await NotificationService().initialize(userId);  // à l'ouverture de session
///   await NotificationService().deleteSubscription(); // avant logout
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Demande la permission, s'abonne au push et enregistre la souscription
  /// dans Supabase. Ne fait rien si la plateforme n'est pas le web.
  Future<void> initialize(String userId) async {
    if (!kIsWeb) return;
    if (_initialized) return;

    try {
      // Appel JavaScript via push_utils.js
      final resultJs = await _jsPushSubscribe(_vapidPublicKey.toJS).toDart;
      final resultStr = resultJs.toDart;

      final Map<String, dynamic> result = jsonDecode(resultStr);

      if (result.containsKey('error')) {
        if (kDebugMode) debugPrint('[Push] Abonnement échoué : ${result['error']}');
        return;
      }

      // Extraire endpoint et clés
      final endpoint = result['endpoint'] as String?;
      final keys = result['keys'] as Map<String, dynamic>?;
      final p256dh = keys?['p256dh'] as String?;
      final auth = keys?['auth'] as String?;

      if (endpoint == null || p256dh == null || auth == null) {
        if (kDebugMode) debugPrint('[Push] Données de souscription incomplètes.');
        return;
      }

      // Enregistrer dans Supabase (upsert sur endpoint pour éviter les doublons)
      await _supabase.from('push_subscriptions').upsert(
        {
          'user_id': userId,
          'endpoint': endpoint,
          'p256dh': p256dh,
          'auth': auth,
        },
        onConflict: 'endpoint',
      );

      _initialized = true;
      if (kDebugMode) debugPrint('[Push] Souscription enregistrée.');
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] Erreur initialize : $e');
    }
  }

  /// Désabonne le navigateur et supprime la souscription de Supabase.
  /// Doit être appelé avant logout.
  Future<void> deleteSubscription() async {
    if (!kIsWeb) return;

    try {
      // Obtenir l'endpoint courant pour le supprimer de Supabase
      // (on appelle d'abord le JS pour récupérer l'endpoint avant de se désabonner)
      final currentEndpoint = await _getCurrentEndpoint();
      if (currentEndpoint != null) {
        await _supabase
            .from('push_subscriptions')
            .delete()
            .eq('endpoint', currentEndpoint);
      }

      // Désabonnement navigateur
      await _jsPushUnsubscribe().toDart;

      _initialized = false;
      if (kDebugMode) debugPrint('[Push] Souscription supprimée.');
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] Erreur deleteSubscription : $e');
    }
  }

  /// Récupère l'endpoint de la souscription active depuis Supabase.
  Future<String?> _getCurrentEndpoint() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final rows = await _supabase
          .from('push_subscriptions')
          .select('endpoint')
          .eq('user_id', userId)
          .limit(1);

      if (rows.isEmpty) return null;
      return rows.first['endpoint'] as String?;
    } catch (_) {
      return null;
    }
  }
}
