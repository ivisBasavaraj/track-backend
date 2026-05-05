import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/fcm_service.dart';

class FCMTokenScreen extends StatefulWidget {
  const FCMTokenScreen({Key? key}) : super(key: key);

  @override
  State<FCMTokenScreen> createState() => _FCMTokenScreenState();
}

class _FCMTokenScreenState extends State<FCMTokenScreen> {
  String? _fcmToken;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final token = await FCMService.getToken();
      setState(() {
        _fcmToken = token;
        _loading = false;
      });
      print('✅ FCM Token: $token');
    } catch (e) {
      setState(() {
        _fcmToken = 'Error: $e';
        _loading = false;
      });
      print('❌ Error getting FCM token: $e');
    }
  }

  void _copyToken() {
    if (_fcmToken != null && !_fcmToken!.startsWith('Error')) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Token copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Token'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'FCM Token:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _fcmToken ?? 'No token available',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _copyToken,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Test Instructions:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Copy the token above'),
                  const Text('2. Open terminal in backend folder'),
                  const Text('3. Run: node test-fcm-flow.js <TOKEN>'),
                  const Text('4. Check your device for notification'),
                ],
              ),
            ),
    );
  }
}
