// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:overlay_support/overlay_support.dart';
import 'screens/login_screen.dart';
import 'screens/modern_login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/modern_supervisor_dashboard.dart';
import 'screens/modern_user_dashboard.dart';
import 'screens/modern_tool_management_screen.dart';
import 'screens/tool_stock_management_screen.dart';
import 'screens/fcm_test_screen.dart';
import 'screens/fcm_token_screen.dart';
import 'ui/app_theme.dart';
import 'services/fcm_service.dart';
import 'services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await FCMService.initialize();
    } catch (e) {
      print('Firebase initialization failed: $e');
    }
  }
  
  // iOS safe area configuration
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  try {
    await Supabase.initialize(
      url: 'https://ynwyjrdrlyyekhxjnzcp.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlud3lqcmRybHl5ZWtoeGpuemNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNjIzNjgsImV4cCI6MjA3NDczODM2OH0.UCnWt-Pmhy94i1TZIYBDH4KhWFw3i42eRZ4Ha4BHIwI',
    );
  } catch (e) {
    print('Supabase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'TrackPro - Modern Production Management',
        theme: AppTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: Colors.white,
        ),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
        home: const FCMWrapper(child: ModernLoginScreen()),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const ModernLoginScreen(),
          '/admin': (context) => const AdminDashboard(adminName: 'Administrator'),
          '/supervisor': (context) => const ModernSupervisorDashboard(supervisorName: 'Supervisor'),
          '/user': (context) => const ModernUserDashboard(userName: 'User', userRole: 'Operator'),
          '/tools': (context) => const ModernToolManagementScreen(),
          '/tool-stock': (context) => const ToolStockManagementScreen(),
          '/login-classic': (context) => const LoginScreen(),
          '/fcm-test': (context) => const FCMTestScreen(),
          '/fcm-token': (context) => const FCMTokenScreen(),
        },
      ),
    );
  }
}

class FCMWrapper extends StatefulWidget {
  final Widget child;
  const FCMWrapper({super.key, required this.child});

  @override
  State<FCMWrapper> createState() => _FCMWrapperState();
}

class _FCMWrapperState extends State<FCMWrapper> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    if (kIsWeb) return;
    
    try {
      String? token = await FCMService.getToken();
      print('✅ FCM Token obtained: ${token?.substring(0, 20)}...');
      
      if (token != null) {
        // Try to update token if user is already logged in
        final authToken = await ApiService.getToken();
        if (authToken != null) {
          final result = await ApiService.updateFcmToken(token);
          if (result['success'] == true) {
            print('✅ FCM Token updated successfully');
          } else {
            print('⚠️ FCM Token update failed: ${result['message']}');
          }
        } else {
          print('⚠️ No auth token, FCM token will be updated after login');
        }
      } else {
        print('❌ Failed to get FCM token');
      }

      FCMService.listenToMessages((message) {
        print('✅ Foreground message: ${message.notification?.title}');
        _showNotification(message);
      });

      FCMService.listenToMessageTaps((message) {
        print('✅ Notification tapped: ${message.notification?.title}');
      });
    } catch (e) {
      print('❌ FCM setup failed: $e');
    }
  }

  void _showNotification(dynamic message) {
    if (kIsWeb) return;
    
    showOverlayNotification((context) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 40),
        elevation: 8,
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF3B82F6),
            child: Icon(Icons.notifications, color: Colors.white),
          ),
          title: Text(message.notification?.title ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(message.notification?.body ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => OverlaySupportEntry.of(context)!.dismiss(),
          ),
        ),
      );
    }, duration: const Duration(seconds: 4));

    FCMService.showNotification(message);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}