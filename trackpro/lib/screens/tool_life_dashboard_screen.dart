import 'package:flutter/material.dart';
import '../models/tool_life_model.dart';
import '../services/tool_life_service.dart';
import '../utils/api_client.dart';

class ToolLifeDashboardScreen extends StatefulWidget {
  const ToolLifeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ToolLifeDashboardScreen> createState() => _ToolLifeDashboardScreenState();
}

class _ToolLifeDashboardScreenState extends State<ToolLifeDashboardScreen> {
  late ToolLifeService _toolLifeService;
  List<MasterTool> _tools = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _toolLifeService = ToolLifeService(ApiClient());
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tools = await _toolLifeService.getAllMasterTools();
      setState(() {
        _tools = tools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'NEAR_END_OF_LIFE':
        return Colors.orange;
      case 'END_OF_LIFE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Life Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTools,
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
                        onPressed: _loadTools,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tools.isEmpty
                  ? const Center(child: Text('No tools found'))
                  : RefreshIndicator(
                      onRefresh: _loadTools,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tools.length,
                        itemBuilder: (context, index) {
                          final tool = _tools[index];
                          final usagePercentage = tool.usagePercentage ?? 0;
                          final statusColor = _getStatusColor(tool.status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tool.toolName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'ID: ${tool.toolId} | ${tool.holderName}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          tool.status.replaceAll('_', ' '),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${tool.cumulativeUsage?.toStringAsFixed(0) ?? '0'} / ${tool.toolLifeThreshold}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${usagePercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: usagePercentage >= 100
                                              ? Colors.red
                                              : usagePercentage >= 90
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (usagePercentage / 100).clamp(0.0, 1.0),
                                      minHeight: 12,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        usagePercentage >= 100
                                            ? Colors.red
                                            : usagePercentage >= 90
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Remaining Life: ${tool.remainingLife?.toStringAsFixed(0) ?? '0'} units',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/tool-life-history',
                                            arguments: tool.toolId,
                                          );
                                        },
                                        icon: const Icon(Icons.history, size: 18),
                                        label: const Text('History'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/tool-usage-entry',
                                            arguments: tool.toolId,
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Record Usage'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/tool-alerts');
        },
        child: const Icon(Icons.notifications),
      ),
    );
  }
}
