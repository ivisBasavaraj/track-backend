import 'package:flutter/material.dart';
import '../models/tool_life_model.dart';
import '../services/tool_life_service.dart';
import '../utils/api_client.dart';
import 'package:intl/intl.dart';

class ToolAlertsScreen extends StatefulWidget {
  const ToolAlertsScreen({Key? key}) : super(key: key);

  @override
  State<ToolAlertsScreen> createState() => _ToolAlertsScreenState();
}

class _ToolAlertsScreenState extends State<ToolAlertsScreen> {
  late ToolLifeService _toolLifeService;
  List<ToolAlert> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _toolLifeService = ToolLifeService(ApiClient());
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final alerts = await _toolLifeService.getActiveAlerts();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Icons.error;
      case 'WARNING':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
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
                        onPressed: _loadAlerts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _alerts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            'No Active Alerts',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('All tools are operating normally'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAlerts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          final alertColor = _getAlertColor(alert.alertSeverity);
                          final alertIcon = _getAlertIcon(alert.alertSeverity);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            child: InkWell(
                              onTap: () => _showAlertDetails(alert),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: alertColor, width: 4),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(alertIcon, color: alertColor, size: 28),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  alert.alertType,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: alertColor,
                                                  ),
                                                ),
                                                Text(
                                                  alert.toolName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: alertColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              alert.alertStatus,
                                              style: TextStyle(
                                                color: alertColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        alert.alertDescription,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Usage: ${alert.cumulativeUsage.toStringAsFixed(0)}/${alert.toolLifeThreshold}',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            '${alert.usagePercentage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: alertColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Components: ${alert.componentsUsed.join(", ")}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(alert.createdDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showAlertDetails(ToolAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertIcon(alert.alertSeverity),
              color: _getAlertColor(alert.alertSeverity),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.alertType)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tool ID', alert.toolId.toString()),
              _buildDetailRow('Tool Name', alert.toolName),
              _buildDetailRow('Threshold', alert.toolLifeThreshold.toString()),
              _buildDetailRow('Current Usage', alert.cumulativeUsage.toStringAsFixed(0)),
              _buildDetailRow('Usage %', '${alert.usagePercentage.toStringAsFixed(2)}%'),
              _buildDetailRow('Remaining Life', '${alert.remainingLife.toStringAsFixed(0)} units'),
              const Divider(),
              const Text(
                'Components Used:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...alert.componentsUsed.map((c) => Text('• $c')),
              const Divider(),
              const Text(
                'Alert Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(alert.alertMessage),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
