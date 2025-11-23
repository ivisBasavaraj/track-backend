// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/modern_login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/modern_supervisor_dashboard.dart';
import 'screens/modern_user_dashboard.dart';
import 'screens/modern_tool_management_screen.dart';
import 'screens/tool_stock_management_screen.dart';
import 'ui/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return MaterialApp(
      title: 'TrackPro - Modern Production Management',
      theme: AppTheme.lightTheme,
      // Use modern login screen as the default entry point
      home: const ModernLoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const ModernLoginScreen(),
        '/admin': (context) => const AdminDashboard(adminName: 'Administrator'),
        '/supervisor': (context) => const ModernSupervisorDashboard(supervisorName: 'Supervisor'),
        '/user': (context) => const ModernUserDashboard(userName: 'User', userRole: 'Operator'),
        '/tools': (context) => const ModernToolManagementScreen(),
        '/tool-stock': (context) => const ToolStockManagementScreen(),
        // Fallback to original screens if needed
        '/login-classic': (context) => const LoginScreen(),
      },
    );
  }
}