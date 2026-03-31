import 'package:flutter/foundation.dart';
import 'notification_service_stub.dart'
    if (dart.library.js_interop) 'notification_service_web.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize(String userId) async {
    if (!kIsWeb) return;
    await initializeWeb(userId);
  }

  Future<void> deleteSubscription() async {
    if (!kIsWeb) return;
    await deleteSubscriptionWeb();
  }
}