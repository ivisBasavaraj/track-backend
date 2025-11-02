// File: lib/screens/incoming_inspection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import '../services/api_service.dart';
import 'login_screen.dart';

class IncomingInspectionScreen extends StatefulWidget {
  const IncomingInspectionScreen({super.key});

  @override
  _IncomingInspectionScreenState createState() => _IncomingInspectionScreenState();
}

class _IncomingInspectionScreenState extends State<IncomingInspectionScreen> {
  List<InspectionUnit> inspectionUnits = [InspectionUnit()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A3985),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Incoming Inspection',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveAllInspections,
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: inspectionUnits.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: InspectionUnitWidget(
                    unit: inspectionUnits[index],
                    unitNumber: index + 1,
                    onRemove: inspectionUnits.length > 1 
                        ? () => _removeUnit(index)
                        : null,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _addNewUnit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3499FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add New Unit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addNewUnit() {
    setState(() {
      inspectionUnits.add(InspectionUnit());
    });
  }

  void _removeUnit(int index) {
    setState(() {
      inspectionUnits.removeAt(index);
    });
  }

  void _saveAllInspections() async {
    bool isValid = true;
    for (int i = 0; i < inspectionUnits.length; i++) {
      if (inspectionUnits[i].componentName.isEmpty) {
        isValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill component name for Unit ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      }
    }

    if (isValid) {
      for (int i = 0; i < inspectionUnits.length; i++) {
        final unit = inspectionUnits[i];
        final inspectionData = {
          'unitNumber': i + 1,
          'componentName': unit.componentName,
          'supplierDetails': unit.supplierDetails,
          'remarks': unit.remarks,
          'duration': unit.completedDuration ?? '00:00:00',
          'isCompleted': unit.isCompleted,
          'timerEvents': unit.timerEvents,
        };
        
        File? imageFile;
        if (unit.imagePath != null) {
          imageFile = File(unit.imagePath!);
        }
        
        final result = await ApiService.createInspection(inspectionData, image: imageFile);
        if (!result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save Unit ${i + 1}: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All inspections saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class InspectionUnit {
  String componentName = '';
  String supplierDetails = '';
  DateTime dateTime = DateTime.now();
  String remarks = '';
  String? imagePath;
  
  // Timer properties
  Stopwatch stopwatch = Stopwatch();
  bool isTimerRunning = false;
  bool isPaused = false;
  String? completedDuration;
  bool isCompleted = false;
  List<Map<String, dynamic>> timerEvents = [];
  String? pendingPauseRemark;

  InspectionUnit();
}

class InspectionUnitWidget extends StatefulWidget {
  final InspectionUnit unit;
  final int unitNumber;
  final VoidCallback? onRemove;

  const InspectionUnitWidget({super.key, 
    required this.unit,
    required this.unitNumber,
    this.onRemove,
  });

  @override
  _InspectionUnitWidgetState createState() => _InspectionUnitWidgetState();
}

class _InspectionUnitWidgetState extends State<InspectionUnitWidget> {
  final TextEditingController _componentNameController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  
  Timer? _timer;
  String _currentElapsedTime = '00:00:00';

  @override
  void initState() {
    super.initState();
    _componentNameController.text = widget.unit.componentName;
    _supplierController.text = widget.unit.supplierDetails;
    _remarksController.text = widget.unit.remarks;
    
    // Removed automatic timer start - timer now starts only when user clicks "Start"
    
    // Update timer display
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (widget.unit.stopwatch.isRunning && mounted) {
        setState(() {
          _currentElapsedTime = _formatTime(widget.unit.stopwatch.elapsed);
        });
      }
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _startTimer() {
    setState(() {
      widget.unit.stopwatch.start();
      widget.unit.isTimerRunning = true;
      widget.unit.timerEvents.add({
        'eventType': 'start',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      widget.unit.stopwatch.stop();
      widget.unit.isTimerRunning = false;
      widget.unit.isPaused = true;
      widget.unit.timerEvents.add({
        'eventType': 'pause',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _showPauseRemarkDialog();
  }

  void _resumeTimer() {
    if (widget.unit.pendingPauseRemark == null || widget.unit.pendingPauseRemark!.isEmpty) {
      _showPauseRemarkDialog();
      return;
    }
    
    setState(() {
      widget.unit.stopwatch.start();
      widget.unit.isTimerRunning = true;
      widget.unit.isPaused = false;
      widget.unit.timerEvents.add({
        'eventType': 'resume',
        'timestamp': DateTime.now().toIso8601String(),
        'pauseRemark': widget.unit.pendingPauseRemark,
      });
      widget.unit.pendingPauseRemark = null;
    });
  }

  void _showPauseRemarkDialog() {
    final TextEditingController remarkController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pause Reason Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide a reason for pausing the timer:'),
              const SizedBox(height: 10),
              TextField(
                controller: remarkController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason for pause...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (remarkController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a reason for pausing'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setState(() {
                  widget.unit.pendingPauseRemark = remarkController.text.trim();
                });
                
                Navigator.of(context).pop();
              },
              child: const Text('Save Reason'),
            ),
          ],
        );
      },
    );
  }

  void _stopTimer() {
    setState(() {
      widget.unit.stopwatch.stop();
      widget.unit.isTimerRunning = false;
      widget.unit.isCompleted = true;
      widget.unit.isPaused = false;
      widget.unit.completedDuration = _formatTime(widget.unit.stopwatch.elapsed);
      widget.unit.timerEvents.add({
        'eventType': 'stop',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3985), Color(0xFF3499FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(48, 58, 57, 133),
            offset: Offset(0, 18),
            blurRadius: 48,
            spreadRadius: -12,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -46,
            top: -46,
            child: _FrostedOrb(
              diameter: 160,
              colors: const [Color(0x66FFFFFF), Color(0x05FFFFFF)],
            ),
          ),
          Positioned(
            left: -58,
            bottom: -58,
            child: _FrostedOrb(
              diameter: 200,
              colors: const [Color(0x33FFFFFF), Colors.transparent],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.97),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1.4,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.72),
                        Colors.white.withOpacity(0.42),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0x113499FF), Color(0x113A3985)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 300),
                                    scale: widget.unit.isCompleted ? 1.05 : 1,
                                    curve: Curves.easeOutBack,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF3499FF), Color(0xFF3A3985)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unit ${widget.unitNumber}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      Text(
                                        widget.unit.isCompleted
                                            ? 'Inspection completed'
                                            : widget.unit.isTimerRunning
                                                ? 'Inspection in progress'
                                                : 'Ready to begin inspection',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color(0xFF111827).withOpacity(0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (widget.onRemove != null)
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: widget.onRemove,
                                  child: Ink(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: const Color(0xFFFFF1F1),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFFD32F2F),
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _buildTimerSection(),
                          const SizedBox(height: 26),
                          _buildCameraSection(),
                          const SizedBox(height: 26),
                          _buildTextField(
                            'Component Name *',
                            _componentNameController,
                            (value) => widget.unit.componentName = value,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            'Supplier Details',
                            _supplierController,
                            (value) => widget.unit.supplierDetails = value,
                          ),
                          const SizedBox(height: 20),
                          _buildDateTimeSection(),
                          const SizedBox(height: 20),
                          _buildTextField(
                            'Remarks/Comments',
                            _remarksController,
                            (value) => widget.unit.remarks = value,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: widget.unit.isCompleted ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.unit.isCompleted ? Colors.green[200]! : Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.unit.isCompleted ? 'Inspection Completed' : 'Inspection Timer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.unit.isCompleted ? Colors.green[700] : Colors.blue[700],
                ),
              ),
              if (widget.unit.isCompleted)
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.unit.isCompleted 
                ? widget.unit.completedDuration! 
                : _currentElapsedTime,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.unit.isCompleted ? Colors.green[700] : Colors.blue[700],
              fontFamily: 'monospace',
            ),
          ),
          if (!widget.unit.isCompleted) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimerButton(
                  'Start',
                  Icons.play_arrow,
                  Colors.green,
                  widget.unit.isTimerRunning ? null : _startTimer,
                ),
                widget.unit.isPaused
                    ? _buildTimerButton(
                        'Resume',
                        Icons.play_arrow,
                        Colors.blue,
                        widget.unit.pendingPauseRemark != null ? _resumeTimer : null,
                      )
                    : _buildTimerButton(
                        'Pause',
                        Icons.pause,
                        Colors.orange,
                        widget.unit.isTimerRunning ? _pauseTimer : null,
                      ),
                _buildTimerButton(
                  'Complete',
                  Icons.stop,
                  Colors.red,
                  _stopTimer,
                ),
              ],
            ),
          ],
          if (widget.unit.isCompleted)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Duration: ${widget.unit.completedDuration}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (widget.unit.timerEvents.where((e) => e['eventType'] == 'pause').isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Paused ${widget.unit.timerEvents.where((e) => e['eventType'] == 'pause').length} time(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (widget.unit.isPaused && widget.unit.pendingPauseRemark == null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Reason required to resume',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildCameraSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: widget.unit.imagePath != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(widget.unit.imagePath!),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.unit.imagePath = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: _openCamera,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to Capture Photo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Live camera only',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF3A3985), Color(0xFF3499FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Focus(
            child: Builder(builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: isFocused
                      ? const LinearGradient(
                          colors: [Color(0x1A3A3985), Color(0x1A3499FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Colors.white, Colors.white],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isFocused ? 0.04 : 0.02),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF3499FF).withOpacity(0.7)
                          : Colors.black.withOpacity(0.08),
                      width: isFocused ? 1.4 : 1,
                    ),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: maxLines,
                    onChanged: onChanged,
                    cursorColor: const Color(0xFF3499FF),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time of Inspection',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${widget.unit.dateTime.day}/${widget.unit.dateTime.month}/${widget.unit.dateTime.year} at ${widget.unit.dateTime.hour}:${widget.unit.dateTime.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  void _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras available')),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(camera: cameras.first),
        ),
      );

      if (result != null) {
        setState(() {
          widget.unit.imagePath = result;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening camera: $e')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _componentNameController.dispose();
    _supplierController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller!.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Capture Photo',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: Stack(
                      children: [
                        CameraPreview(_controller!),
                        // Watermark overlay
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _getCurrentDate(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getCurrentTime(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: Center(
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: _takePictureWithWatermark,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }
        },
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _takePictureWithWatermark() async {
    try {
      await _initializeControllerFuture;
      
      // Capture the widget with watermark as image
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process image')),
        );
        return;
      }
      
      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save the image with watermark
      final directory = await getTemporaryDirectory();
      final imagePath = path.join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      
      File imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      Navigator.pop(context, imagePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _FrostedOrb extends StatelessWidget {
  final double diameter;
  final List<Color> colors;

  const _FrostedOrb({
    required this.diameter,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}