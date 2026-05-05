// File: lib/services/fcm_helper_stub.dart
// Stub for web platform

class FCMHelper {
  static Future<void> initialize() async {}
  static Future<String?> getToken() async => null;
  static void listenToMessages(Function(dynamic) onMessage) {}
  static void listenToMessageTaps(Function(dynamic) onTap) {}
  static Future<void> showNotification(dynamic message) async {}
}

Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {}
