import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _vapidPublicKey = 'BH-mcoCnWW7AxhCyrwqDdqTklAedi8Xzku0wPXLbW1h0wi3PNH9SXiVk-fGGi78fg7a2XDqzNgTrks5hJFesdpU';

@JS('_pushUtils.subscribe')
external JSPromise<JSString> _jsPushSubscribe(JSString vapidKey);

@JS('_pushUtils.unsubscribe')
external JSPromise<JSString> _jsPushUnsubscribe();

bool _initialized = false;
SupabaseClient get _supabase => Supabase.instance.client;

Future<void> initializeWeb(String userId) async {
  if (_initialized) return;
  try {
    final resultJs = await _jsPushSubscribe(_vapidPublicKey.toJS).toDart;
    final result = jsonDecode(resultJs.toDart) as Map<String, dynamic>;
    if (result.containsKey('error')) return;

    final endpoint = result['endpoint'] as String?;
    final keys = result['keys'] as Map<String, dynamic>?;
    final p256dh = keys?['p256dh'] as String?;
    final auth = keys?['auth'] as String?;
    if (endpoint == null || p256dh == null || auth == null) return;

    await _supabase.from('push_subscriptions').upsert(
      {'user_id': userId, 'endpoint': endpoint, 'p256dh': p256dh, 'auth': auth},
      onConflict: 'endpoint',
    );
    _initialized = true;
  } catch (e) {
    if (kDebugMode) debugPrint('[Push] Erreur initialize : $e');
  }
}

Future<void> deleteSubscriptionWeb() async {
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      final rows = await _supabase
          .from('push_subscriptions')
          .select('endpoint')
          .eq('user_id', userId)
          .limit(1);
      if (rows.isNotEmpty) {
        await _supabase
            .from('push_subscriptions')
            .delete()
            .eq('endpoint', rows.first['endpoint'] as String);
      }
    }
    await _jsPushUnsubscribe().toDart;
    _initialized = false;
  } catch (e) {
    if (kDebugMode) debugPrint('[Push] Erreur deleteSubscription : $e');
  }
}