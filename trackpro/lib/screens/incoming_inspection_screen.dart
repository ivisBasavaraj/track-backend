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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Incoming Inspection',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Color(0xFF3A3985)),
            onPressed: _saveAllInspections,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF6B7280)),
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: inspectionUnits.length,
              itemBuilder: (context, index) {
                return InspectionUnitWidget(
                  unit: inspectionUnits[index],
                  unitNumber: index + 1,
                  onRemove: inspectionUnits.length > 1 
                      ? () => _removeUnit(index)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton.extended(
          onPressed: _addNewUnit,
          backgroundColor: const Color(0xFF3A3985),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add New Unit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3985).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_rounded,
                    color: Color(0xFF3A3985),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.onRemove != null)
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTimerSection(),
        const SizedBox(height: 20),
        _buildCameraSection(),
        const SizedBox(height: 20),
        _buildTextField(
          'Component Name *',
          _componentNameController,
          (value) => widget.unit.componentName = value,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Supplier Details',
          _supplierController,
          (value) => widget.unit.supplierDetails = value,
        ),
        const SizedBox(height: 16),
        _buildDateTimeSection(),
        const SizedBox(height: 16),
        _buildTextField(
          'Remarks/Comments',
          _remarksController,
          (value) => widget.unit.remarks = value,
          maxLines: 3,
        ),
        const SizedBox(height: 30),
        if (widget.unitNumber < 100) // Visual separator between units
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(height: 20),
      ],
    );
  }



  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.unit.isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.unit.isCompleted ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFF8B5CF6).withOpacity(0.2),
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
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: widget.unit.isCompleted ? const Color(0xFF065F46) : const Color(0xFF5B21B6),
                ),
              ),
              if (widget.unit.isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.unit.isCompleted 
                ? widget.unit.completedDuration! 
                : _currentElapsedTime,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.unit.isCompleted ? const Color(0xFF065F46) : const Color(0xFF5B21B6),
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          if (!widget.unit.isCompleted) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimerButton(
                  'Start',
                  Icons.play_arrow_rounded,
                  const Color(0xFF10B981),
                  widget.unit.isTimerRunning ? null : _startTimer,
                ),
                const SizedBox(width: 8),
                widget.unit.isPaused
                    ? _buildTimerButton(
                        'Resume',
                        Icons.play_arrow_rounded,
                        const Color(0xFF3B82F6),
                        widget.unit.pendingPauseRemark != null ? _resumeTimer : null,
                      )
                    : _buildTimerButton(
                        'Pause',
                        Icons.pause_rounded,
                        const Color(0xFFF59E0B),
                        widget.unit.isTimerRunning ? _pauseTimer : null,
                      ),
                const SizedBox(width: 8),
                _buildTimerButton(
                  'Complete',
                  Icons.stop_rounded,
                  const Color(0xFFEF4444),
                  _stopTimer,
                ),
              ],
            ),
          ],
          if (widget.unit.isCompleted)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total Duration: ${widget.unit.completedDuration}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (widget.unit.timerEvents.where((e) => e['eventType'] == 'pause').isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Paused ${widget.unit.timerEvents.where((e) => e['eventType'] == 'pause').length} time(s)',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (widget.unit.isPaused && widget.unit.pendingPauseRemark == null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Reason required to resume',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.bold,
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
        backgroundColor: onPressed != null ? color : Colors.grey[200],
        foregroundColor: onPressed != null ? Colors.white : Colors.grey[500],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reference Photo',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: widget.unit.imagePath != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(widget.unit.imagePath!),
                        width: double.infinity,
                        height: 180,
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _openCamera,
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3985).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 32,
                          color: Color(0xFF3A3985),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Take Inspection Photo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Live camera capture with watermark',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          cursorColor: const Color(0xFF3A3985),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3A3985), width: 1.5),
            ),
            isDense: true,
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time of Inspection',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Text(
                '${widget.unit.dateTime.day}/${widget.unit.dateTime.month}/${widget.unit.dateTime.year} at ${widget.unit.dateTime.hour}:${widget.unit.dateTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
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
