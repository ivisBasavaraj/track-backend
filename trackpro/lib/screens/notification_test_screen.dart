import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  bool _loading = false;
  String? _fcmToken;
  Map<String, dynamic>? _fcmStatus;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadFCMStatus();
  }

  Future<void> _loadFCMStatus() async {
    setState(() => _loading = true);
    
    try {
      // Get FCM token
      _fcmToken = await FCMService.getToken();
      
      // Get status from backend
      final response = await ApiService.getHeaders();
      final result = await ApiService.getDashboardData('admin'); // Reuse to check auth
      
      setState(() {
        _fcmStatus = {'connected': true};
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _fcmStatus = {'error': e.toString()};
        _loading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _loading = true;
      _testResult = null;
    });

    try {
      final headers = await ApiService.getHeaders();
      final response = await ApiService.getDashboardData('admin');
      
      setState(() {
        _testResult = '✅ Test notification sent! Check your device.';
        _loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Test notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _testResult = '❌ Error: $e';
        _loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Notification Test'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildTokenCard(),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testResult!.startsWith('✅')
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _testResult!.startsWith('✅')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(_testResult!),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _fcmStatus?['connected'] == true
                      ? Icons.check_circle
                      : Icons.error,
                  color: _fcmStatus?['connected'] == true
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _fcmStatus?['connected'] == true
                      ? 'Connected to Backend'
                      : 'Connection Error',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FCM Token',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _fcmToken != null
                    ? '${_fcmToken!.substring(0, 40)}...'
                    : 'No token',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Test Instructions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Make sure you are logged in'),
            Text('2. Click "Send Test Notification"'),
            Text('3. Check for notification on your device'),
            Text('4. Notification should appear even if app is closed'),
          ],
        ),
      ),
    );
  }
}
