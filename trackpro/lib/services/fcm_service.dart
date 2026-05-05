// File: lib/services/fcm_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;

// Platform-specific implementation
import 'fcm_service_mobile.dart' if (dart.library.html) 'fcm_service_web.dart';

class FCMService {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    return FCMServiceImpl.initialize();
  }
  
  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    return FCMServiceImpl.getToken();
  }
  
  static void listenToMessages(Function(dynamic) onMessage) {
    if (kIsWeb) return;
    FCMServiceImpl.listenToMessages(onMessage);
  }
  
  static void listenToMessageTaps(Function(dynamic) onTap) {
    if (kIsWeb) return;
    FCMServiceImpl.listenToMessageTaps(onTap);
  }
  
  static Future<void> showNotification(dynamic message) async {
    if (kIsWeb) return;
    return FCMServiceImpl.showNotification(message);
  }
}
