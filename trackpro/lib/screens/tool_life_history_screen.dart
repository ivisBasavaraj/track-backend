import 'package:flutter/material.dart';
import '../models/tool_life_model.dart';
import '../services/tool_life_service.dart';
import '../utils/api_client.dart';
import 'package:intl/intl.dart';

class ToolLifeHistoryScreen extends StatefulWidget {
  final int toolId;

  const ToolLifeHistoryScreen({super.key, required this.toolId});

  @override
  State<ToolLifeHistoryScreen> createState() => _ToolLifeHistoryScreenState();
}

class _ToolLifeHistoryScreenState extends State<ToolLifeHistoryScreen> {
  late ToolLifeService _toolLifeService;
  List<ToolUsageLog> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _toolLifeService = ToolLifeService(ApiClient());
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _toolLifeService.getToolHistory(widget.toolId);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tool ${widget.toolId} History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? const Center(child: Text('No usage history found'))
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final isAlert = log.alertTriggered;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isAlert
                                ? (log.alertType == 'CRITICAL'
                                    ? Colors.red[50]
                                    : Colors.orange[50])
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log.componentId,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isAlert)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: log.alertType == 'CRITICAL'
                                                ? Colors.red
                                                : Colors.orange,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            log.alertType,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('MMM dd, yyyy HH:mm:ss').format(log.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Holes',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            log.noOfHoles.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Cutting Length',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            log.cuttingLength.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Usage Score',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            log.usageScore.toStringAsFixed(0),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Before: ${log.cumulativeTotalBefore.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      const Icon(Icons.arrow_forward, size: 16),
                                      Text(
                                        'After: ${log.cumulativeTotalAfter.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Usage: ${log.usagePercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: log.usagePercentage >= 100
                                              ? Colors.red
                                              : log.usagePercentage >= 90
                                                  ? Colors.orange
                                                  : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Remaining: ${log.remainingLife.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
