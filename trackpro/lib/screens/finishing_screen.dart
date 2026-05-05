// File: lib/screens/finishing_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/tools_service.dart';
import 'login_screen.dart';

class FinishingScreen extends StatefulWidget {
  const FinishingScreen({super.key});

  @override
  _FinishingScreenState createState() => _FinishingScreenState();
}

class _FinishingScreenState extends State<FinishingScreen> {
  String? selectedTool;
  String partComponentId = '';
  String operatorName = '';
  String remarks = '';
  String? _finishingRecordId;
  DateTime? _pauseStartTime;
  bool _isPaused = false;
  final TextEditingController _remarksController = TextEditingController();
  List<Map<String, dynamic>> _pauses = [];
  
  // Tool life tracking
  final TextEditingController _noOfHolesController = TextEditingController();
  final TextEditingController _cuttingLengthController = TextEditingController();
  int? _selectedToolId;
  Map<String, dynamic>? _toolStatus;
  
  List<Map<String, dynamic>> customToolData = [];
  
  // Timer variables
  final Stopwatch _settingStopwatch = Stopwatch();
  final Stopwatch _finishingStopwatch = Stopwatch();
  Timer? _timer;
  String _settingElapsedTime = '00:00:00';
  String _finishingElapsedTime = '00:00:00';
  bool _isSettingRunning = false;
  bool _isFinishingRunning = false;
  bool _isSettingCompleted = false;
  String _currentPauseRemarks = '';

  List<String> tools = [];
  
  // Assigned finishing data
  String? _assignedProductName;
  String? _assignedToolListName;
  String? _assignedDiagramUrl;
  bool _isLoadingAssignment = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadAssignedFinishingData();
  }
  
  int? _extractToolIdFromToolName(String toolName) {
    final match = RegExp(r'^(\d+)').firstMatch(toolName);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
  
  void _loadAssignedFinishingData() async {
    try {
      final userData = await ApiService.getCurrentUser();
      if (userData['finishingAssignment'] != null) {
        final assignment = userData['finishingAssignment'];
        setState(() {
          _assignedProductName = assignment['productName'];
          _assignedToolListName = assignment['toolListName'];
          _assignedDiagramUrl = assignment['diagramUrl'];
          selectedTool = _assignedToolListName;
          _isLoadingAssignment = false;
        });
        if (selectedTool != null) {
          _loadToolData();
        }
      } else {
        setState(() {
          _isLoadingAssignment = false;
        });
        _loadAvailableTools();
      }
    } catch (e) {
      setState(() {
        _isLoadingAssignment = false;
      });
      _loadAvailableTools();
    }
  }
  
  void _loadToolStatus() async {
    if (_selectedToolId != null) {
      final status = await ApiService.getToolStatus(_selectedToolId!);
      if (status['success']) {
        setState(() {
          _toolStatus = status['data'];
        });
      }
    }
  }
  
  void _loadAvailableTools() async {
    try {
      final toolsService = ToolsService();
      final toolLists = await toolsService.getAllToolLists();
      print('Loaded ${toolLists.length} components');
      setState(() {
        tools = toolLists.map((tool) => tool.toolName).toList();
        print('Component names: $tools');
        if (tools.isNotEmpty && selectedTool == null) {
          selectedTool = tools[0];
          _loadToolData();
        }
      });
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load components: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _loadToolData() async {
    if (selectedTool != null) {
      try {
        final response = await ApiService.getToolListByName(selectedTool!);
        
        List<Map<String, dynamic>> data = [];
        
        if (response['data'] != null && response['data']['sheets'] != null) {
          final sheets = response['data']['sheets'] as List;
          if (sheets.isNotEmpty && sheets[0]['toolData'] != null) {
            final toolData = sheets[0]['toolData'] as List;
            data = toolData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          }
        }
        
        print('Loaded ${data.length} tools for $selectedTool');
        setState(() {
          customToolData = data;
        });
      } catch (e) {
        print('Error: $e');
        setState(() {
          customToolData = [];
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_settingStopwatch.isRunning) {
          _settingElapsedTime = _formatTime(_settingStopwatch.elapsed);
        }
        if (_finishingStopwatch.isRunning) {
          _finishingElapsedTime = _formatTime(_finishingStopwatch.elapsed);
        }
      });
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _startSettingTimer() async {
    if (partComponentId.trim().isEmpty || operatorName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Part/Component ID and Operator Name before starting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_finishingRecordId == null && selectedTool != null) {
      final result = await ApiService.createFinishing({
        'toolUsed': selectedTool!,
        'toolStatus': 'Setting',
        'partComponentId': partComponentId.isEmpty ? 'TBD' : partComponentId,
        'operatorName': operatorName.isEmpty ? 'TBD' : operatorName,
        'status': 'setting',
      });
      
      if (result['success']) {
        _finishingRecordId = result['finishing']['_id'];
      }
    }
    
    setState(() {
      _settingStopwatch.start();
      _isSettingRunning = true;
    });
  }

  void _stopSettingTimer() async {
    if (_finishingRecordId != null) {
      await ApiService.updateFinishing(_finishingRecordId!, {
        'settingDuration': _formatTime(_settingStopwatch.elapsed),
        'status': 'setting_completed',
      });
    }
    
    setState(() {
      _settingStopwatch.stop();
      _isSettingRunning = false;
      _isSettingCompleted = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Setting completed! You can now start Finishing timer.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _startFinishingTimer() async {
    if (!_isSettingCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete Setting timer before starting Finishing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_isPaused && _pauseStartTime != null) {
      final pauseEnd = DateTime.now();
      final pauseDuration = pauseEnd.difference(_pauseStartTime!).inSeconds;
      
      _pauses.add({
        'startTime': _pauseStartTime!.toIso8601String(),
        'endTime': pauseEnd.toIso8601String(),
        'durationSeconds': pauseDuration,
        'remarks': _currentPauseRemarks,
      });
      
      if (_finishingRecordId != null) {
        await ApiService.updateFinishing(_finishingRecordId!, {
          'pauses': _pauses,
          'pauseCount': _pauses.length,
        });
      }
    }
    
    setState(() {
      _isPaused = false;
    });
    
    if (_finishingRecordId != null) {
      await ApiService.updateFinishing(_finishingRecordId!, {
        'toolStatus': 'Working',
        'status': 'in_progress',
      });
    }
    
    setState(() {
      _finishingStopwatch.start();
      _isFinishingRunning = true;
    });
  }

  void _pauseFinishingTimer() async {
    final dialogRemarksController = TextEditingController();
    final pauseRemarks = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pause Process'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pause #${_pauses.length + 1} - Please provide remarks:'),
            const SizedBox(height: 15),
            TextField(
              controller: dialogRemarksController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter reason for pausing...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final remarksText = dialogRemarksController.text.trim();
              if (remarksText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Remarks are required to pause'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                Navigator.pop(context, remarksText);
              }
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
    
    dialogRemarksController.dispose();
    
    if (pauseRemarks != null && pauseRemarks.isNotEmpty) {
      setState(() {
        _currentPauseRemarks = pauseRemarks;
        _finishingStopwatch.stop();
        _isFinishingRunning = false;
        _pauseStartTime = DateTime.now();
        _isPaused = true;
      });
    }
  }

  void _stopFinishingTimer() async {
    if (_finishingRecordId != null) {
      await ApiService.updateFinishing(_finishingRecordId!, {
        'status': 'completed',
        'settingDuration': _formatTime(_settingStopwatch.elapsed),
        'finishingDuration': _formatTime(_finishingStopwatch.elapsed),
        'totalDuration': _formatTime(_settingStopwatch.elapsed + _finishingStopwatch.elapsed),
      });
    }
    
    await _showToolUsageDialog();
    
    setState(() {
      _settingStopwatch.stop();
      _settingStopwatch.reset();
      _finishingStopwatch.stop();
      _finishingStopwatch.reset();
      _isSettingRunning = false;
      _isFinishingRunning = false;
      _isSettingCompleted = false;
      _currentPauseRemarks = '';
      _pauseStartTime = null;
      _finishingRecordId = null;
      _settingElapsedTime = '00:00:00';
      _finishingElapsedTime = '00:00:00';
      _isPaused = false;
      _pauses = [];
      _noOfHolesController.clear();
      _cuttingLengthController.clear();
    });
  }
  
  Future<void> _showToolUsageDialog() async {
    if (selectedTool == null) return;
    
    if (selectedTool == 'AMS-141 COLUMN') {
      await _recordAms141ToolUsage();
      return;
    }
    
    _selectedToolId = _extractToolIdFromToolName(selectedTool!);
    if (_selectedToolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot extract tool ID'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Record Tool Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tool: $selectedTool', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _noOfHolesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Holes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cuttingLengthController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cutting Length (mm)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              final noOfHoles = int.tryParse(_noOfHolesController.text);
              final cuttingLength = double.tryParse(_cuttingLengthController.text);
              
              if (noOfHoles == null || cuttingLength == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid numbers'), backgroundColor: Colors.red),
                );
                return;
              }
              
              final result = await ApiService.recordToolUsage(
                toolId: _selectedToolId!,
                componentId: partComponentId.isEmpty ? 'UNKNOWN' : partComponentId,
                noOfHoles: noOfHoles,
                cuttingLength: cuttingLength,
              );
              
              Navigator.pop(context);
              
              if (result['success']) {
                final data = result['data'];
                final alertType = data['alert_type'];
                
                if (alertType != 'NONE') {
                  _showToolAlertDialog(data);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tool usage recorded: ${data['usage_percentage']}% used'), backgroundColor: Colors.green),
                  );
                }
                _loadToolStatus();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${result['message']}'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3499FF)),
            child: const Text('Record', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _recordAms141ToolUsage() async {
    final toolsWithUsage = customToolData.where((tool) {
      final holes = tool['noOfHolesInComponent'];
      final length = tool['cuttingLength'];
      return holes != null && holes.toString().isNotEmpty && 
             length != null && length.toString().isNotEmpty;
    }).toList();
    
    if (toolsWithUsage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tool usage data found in AMS-141 COLUMN'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    int successCount = 0;
    List<String> alerts = [];
    
    for (var tool in toolsWithUsage) {
      final toolId = tool['atcPocketNo'];
      final noOfHoles = int.tryParse(tool['noOfHolesInComponent'].toString());
      final cuttingLength = double.tryParse(tool['cuttingLength'].toString());
      
      if (toolId != null && noOfHoles != null && cuttingLength != null) {
        final result = await ApiService.recordToolUsage(
          toolId: toolId,
          componentId: partComponentId.isEmpty ? 'AMS-141' : partComponentId,
          noOfHoles: noOfHoles,
          cuttingLength: cuttingLength,
        );
        
        if (result['success']) {
          successCount++;
          final data = result['data'];
          if (data['alert_type'] != 'NONE') {
            alerts.add('${data['tool_name']}: ${data['alert_type']}');
          }
        }
      }
    }
    
    if (alerts.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tool Life Alerts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recorded usage for $successCount tools'),
              const SizedBox(height: 10),
              const Text('Alerts:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...alerts.map((alert) => Text('• $alert')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recorded usage for $successCount tools successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _showToolAlertDialog(Map<String, dynamic> data) {
    final alertType = data['alert_type'];
    Color alertColor = Colors.blue;
    IconData alertIcon = Icons.info;
    
    if (alertType == 'CRITICAL') {
      alertColor = Colors.red;
      alertIcon = Icons.error;
    } else if (alertType == 'WARNING') {
      alertColor = Colors.orange;
      alertIcon = Icons.warning;
    } else if (alertType == 'ORDER') {
      alertColor = Colors.blue;
      alertIcon = Icons.shopping_cart;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(alertIcon, color: alertColor, size: 28),
            const SizedBox(width: 10),
            Text('Tool Life Alert', style: TextStyle(color: alertColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tool: ${data['tool_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Usage: ${data['usage_percentage']}%'),
            Text('Remaining Life: ${data['remaining_life']} units'),
            const SizedBox(height: 10),
            Text(data['recommendation'], style: TextStyle(color: alertColor, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A3985),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Finishing',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveFinishingData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ApiService.removeToken();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Setting Timer Section
            _buildSettingTimerSection(),
            const SizedBox(height: 20),
            
            // Finishing Timer Section
            _buildFinishingTimerSection(),
            const SizedBox(height: 30),

            // Writing Remarks Card (shown when paused)
            if (_isPaused) ...[
              _buildWritingRemarksCard(),
              const SizedBox(height: 30),
            ],

            // Component Selection Section
            _buildSectionTitle(_assignedProductName != null ? 'Assigned Component' : 'Component Selection'),
            const SizedBox(height: 15),
            
            // Display assigned product name
            if (_assignedProductName != null) ...[
              _buildReadOnlyField('Product Name', _assignedProductName!),
              const SizedBox(height: 15),
            ],
            
            // Display assigned tool list (read-only) or dropdown
            if (_assignedToolListName != null)
              _buildReadOnlyField('Tool List', _assignedToolListName!)
            else if (_isLoadingAssignment)
              const Center(child: CircularProgressIndicator())
            else if (tools.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No components uploaded. Please upload component lists first.'),
                ),
              )
            else
              _buildDropdown(
                'Select Component *',
                selectedTool,
                tools,
                (value) {
                  setState(() {
                    selectedTool = value;
                    _selectedToolId = _extractToolIdFromToolName(value!);
                    _loadToolData();
                    _loadToolStatus();
                  });
                },
              ),
            const SizedBox(height: 30),

            // Data Entry Fields Section
            _buildSectionTitle('Data Entry Fields'),
            const SizedBox(height: 15),

            _buildTextField(
              'Part/Component ID *',
              (value) => partComponentId = value,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              'Operator Name *',
              (value) => operatorName = value,
            ),
            const SizedBox(height: 15),

            _buildTextFieldWithController(
              'Remarks/Comments',
              _remarksController,
              (value) => remarks = value,
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            // Tool Life Status
            if (_selectedToolId != null && _toolStatus != null) ...[
              _buildSectionTitle('Tool Life Status'),
              const SizedBox(height: 15),
              _buildToolLifeStatus(),
              const SizedBox(height: 30),
            ],

            // Component Tool Details Section
            if (selectedTool != null) ...[
              _buildSectionTitle('Component Tool Details'),
              const SizedBox(height: 15),
              _buildToolDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWritingRemarksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3499FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3499FF),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pause_circle,
                color: Color(0xFF3499FF),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Process Paused #${_pauses.length + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A3985),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Pause Reason:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A3985),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3499FF).withOpacity(0.3)),
            ),
            child: Text(
              _currentPauseRemarks,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Click Start to resume the process',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTimerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[700]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Setting Timer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_isSettingCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              _settingElapsedTime,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimerButton(
                'Start',
                Icons.play_arrow,
                Colors.green,
                (_isSettingRunning || _isSettingCompleted) ? null : _startSettingTimer,
              ),
              _buildTimerButton(
                'Stop',
                Icons.stop,
                Colors.red,
                _isSettingRunning ? _stopSettingTimer : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishingTimerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3985), Color(0xFF3499FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3499FF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Finishing Timer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (!_isSettingCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Complete Setting First',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              _finishingElapsedTime,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimerButton(
                'Start',
                Icons.play_arrow,
                Colors.green,
                _isFinishingRunning ? null : _startFinishingTimer,
              ),
              _buildTimerButton(
                'Pause',
                Icons.pause,
                Colors.orange,
                _isFinishingRunning ? _pauseFinishingTimer : null,
              ),
              _buildTimerButton(
                'Stop',
                Icons.stop,
                Colors.red,
                _stopFinishingTimer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerButton(String label, IconData icon, Color color, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey[300],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3A3985),
      ),
    );
  }
  
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildToolDetails() {
    if (customToolData.isNotEmpty) {
      return _buildCustomToolTable();
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Center(
          child: Text(
            'No tool data available. Upload Excel file to add custom tool data.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
  }

  Widget _buildTableRow(Map<String, dynamic> tool) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text('${tool['slNo']}', style: _cellStyle())),
          Expanded(child: Text('${tool['qty']}', style: _cellStyle())),
          Expanded(flex: 3, child: Text('${tool['toolName']}', style: _cellStyle())),
          Expanded(flex: 2, child: Text('${tool['toolDer']}', style: _cellStyle())),
          Expanded(child: Text('${tool['toolNo']}', style: _cellStyle())),
          Expanded(child: Text('${tool['magazine']}', style: _cellStyle())),
          Expanded(child: Text('${tool['pocket']}', style: _cellStyle())),
        ],
      ),
    );
  }

  TextStyle _cellStyle() {
    return const TextStyle(
      fontSize: 9,
      color: Colors.black87,
    );
  }

  void _saveFinishingData() async {
    if (selectedTool == null || selectedTool!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a component'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (partComponentId.isEmpty || operatorName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final finishingData = {
      'toolUsed': selectedTool!,
      'toolStatus': 'Working',
      'partComponentId': partComponentId,
      'operatorName': operatorName,
      'remarks': remarks,
      'settingDuration': _formatTime(_settingStopwatch.elapsed),
      'finishingDuration': _formatTime(_finishingStopwatch.elapsed),
      'isCompleted': !_isFinishingRunning,
    };
    
    final result = await ApiService.createFinishing(finishingData);
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finishing data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  
  Widget _buildCustomToolTable() {
    final headers = customToolData.isNotEmpty ? customToolData[0].keys.toList() : [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3499FF).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: headers.map((header) => 
                  SizedBox(
                    width: 120,
                    child: Text(header.toString().toUpperCase(), style: _headerStyle()),
                  )
                ).toList(),
              ),
            ),
            ...customToolData.map((tool) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 0.5)),
              ),
              child: Row(
                children: headers.map((header) => 
                  SizedBox(
                    width: 120,
                    child: Text('${tool[header] ?? ''}', style: _cellStyle()),
                  )
                ).toList(),
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextFieldWithController(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildToolLifeStatus() {
    if (_toolStatus == null) return const SizedBox();
    
    final usagePercentage = double.tryParse(_toolStatus!['usage_percentage'].toString()) ?? 0;
    final cumulativeUsage = _toolStatus!['cumulative_usage'] ?? 0;
    final threshold = _toolStatus!['tool_life_threshold'] ?? 1;
    final remainingLife = _toolStatus!['remaining_life'] ?? 0;
    final alertStatus = _toolStatus!['alert_status'] ?? 'NONE';
    
    Color statusColor = Colors.green;
    if (alertStatus == 'CRITICAL') {
      statusColor = Colors.red;
    } else if (alertStatus == 'WARNING') {
      statusColor = Colors.orange;
    } else if (usagePercentage >= 75) {
      statusColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usage: ${usagePercentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(alertStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: usagePercentage / 100,
            backgroundColor: Colors.grey[200],
            color: statusColor,
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cumulative Usage', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('$cumulativeUsage / $threshold', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Remaining Life', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('$remainingLife units', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _remarksController.dispose();
    _noOfHolesController.dispose();
    _cuttingLengthController.dispose();
    super.dispose();
  }
}