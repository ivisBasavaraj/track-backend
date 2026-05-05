// File: lib/services/fcm_helper.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMHelper {
  static final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    if (kIsWeb) return;
    
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await notificationsPlugin.initialize(initializationSettings);
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    await notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  }
  
  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await FirebaseMessaging.instance.getToken();
  }
  
  static void listenToMessages(Function(RemoteMessage) onMessage) {
    if (kIsWeb) return;
    FirebaseMessaging.onMessage.listen(onMessage);
  }
  
  static void listenToMessageTaps(Function(RemoteMessage) onTap) {
    if (kIsWeb) return;
    FirebaseMessaging.onMessageOpenedApp.listen(onTap);
  }
  
  static Future<void> showNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    
    await notificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}
