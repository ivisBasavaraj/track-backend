import 'package:flutter/material.dart';
import '../services/tool_life_service.dart';
import '../utils/api_client.dart';

class ToolUsageEntryScreen extends StatefulWidget {
  final int? toolId;

  const ToolUsageEntryScreen({Key? key, this.toolId}) : super(key: key);

  @override
  State<ToolUsageEntryScreen> createState() => _ToolUsageEntryScreenState();
}

class _ToolUsageEntryScreenState extends State<ToolUsageEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late ToolLifeService _toolLifeService;

  final _toolIdController = TextEditingController();
  final _noOfHolesController = TextEditingController();
  final _cuttingLengthController = TextEditingController();

  String _selectedComponent = 'AMS-141';
  final List<String> _components = [
    'AMS-141',
    'AMS-915',
    'AMS-103',
    'AMS-477',
  ];

  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _toolLifeService = ToolLifeService(ApiClient());
    if (widget.toolId != null) {
      _toolIdController.text = widget.toolId.toString();
    }
  }

  @override
  void dispose() {
    _toolIdController.dispose();
    _noOfHolesController.dispose();
    _cuttingLengthController.dispose();
    super.dispose();
  }

  Future<void> _submitUsage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _result = null;
    });

    try {
      final result = await _toolLifeService.recordToolUsage(
        toolId: int.parse(_toolIdController.text),
        componentId: _selectedComponent,
        noOfHoles: int.parse(_noOfHolesController.text),
        cuttingLength: double.parse(_cuttingLengthController.text),
      );

      setState(() {
        _result = result;
        _isSubmitting = false;
      });

      if (result['alert_type'] != 'NONE') {
        _showAlertDialog(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tool usage recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAlertDialog(Map<String, dynamic> result) {
    final alertType = result['alert_type'];
    final isCritical = alertType == 'CRITICAL';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCritical ? Icons.error : Icons.warning,
              color: isCritical ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(isCritical ? 'CRITICAL ALERT' : 'WARNING'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['recommendation'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Tool: ${result['tool_name']}'),
            Text('Usage: ${result['cumulative_total']}/${result['tool_life_threshold']}'),
            Text('Percentage: ${result['usage_percentage']}%'),
            Text('Remaining: ${result['remaining_life']} units'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Tool Usage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedComponent,
                decoration: const InputDecoration(
                  labelText: 'Component',
                  border: OutlineInputBorder(),
                ),
                items: _components.map((component) {
                  return DropdownMenuItem(
                    value: component,
                    child: Text(component),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedComponent = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toolIdController,
                decoration: const InputDecoration(
                  labelText: 'Tool ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter tool ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noOfHolesController,
                decoration: const InputDecoration(
                  labelText: 'Number of Holes',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of holes';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cuttingLengthController,
                decoration: const InputDecoration(
                  labelText: 'Cutting Length',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cutting length';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitUsage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Usage', style: TextStyle(fontSize: 16)),
              ),
              if (_result != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usage Recorded',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildResultRow('Tool', _result!['tool_name']),
                        _buildResultRow('Usage Score', _result!['usage_score'].toString()),
                        _buildResultRow(
                          'Cumulative Total',
                          '${_result!['cumulative_total']} / ${_result!['tool_life_threshold']}',
                        ),
                        _buildResultRow('Usage %', '${_result!['usage_percentage']}%'),
                        _buildResultRow('Remaining Life', '${_result!['remaining_life']} units'),
                        _buildResultRow('Status', _result!['status']),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _result!['recommendation'],
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
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
