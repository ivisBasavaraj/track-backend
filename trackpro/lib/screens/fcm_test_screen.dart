import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/fcm_service.dart';

class FCMTestScreen extends StatefulWidget {
  const FCMTestScreen({super.key});

  @override
  State<FCMTestScreen> createState() => _FCMTestScreenState();
}

class _FCMTestScreenState extends State<FCMTestScreen> {
  String? _fcmToken;
  bool _isLoading = true;
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      final token = await FCMService.getToken();
      setState(() {
        _fcmToken = token;
        _isLoading = false;
      });

      FCMService.listenToMessages((message) {
        setState(() {
          _messages.insert(0, '${message.notification?.title}: ${message.notification?.body}');
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add('Error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Test'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _fcmToken != null ? Icons.check_circle : Icons.error,
                                color: _fcmToken != null ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FCM Status: ${_fcmToken != null ? "Connected" : "Failed"}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('FCM Token:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _fcmToken ?? 'No token available',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _fcmToken != null
                                ? () {
                                    Clipboard.setData(ClipboardData(text: _fcmToken!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Token copied!')),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Token'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Received Messages:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_messages.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No messages received yet'),
                      ),
                    )
                  else
                    ..._messages.map((msg) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications, color: Color(0xFF3B82F6)),
                            title: Text(msg),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
