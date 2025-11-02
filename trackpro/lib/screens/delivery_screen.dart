// File: lib/screens/delivery_screen.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _deliveryAddressController = TextEditingController();
  final TextEditingController _vehicleDetailsController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverContactController = TextEditingController();
  final TextEditingController _partIdController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  File? _deliveryProofImage;

  final ImagePicker _picker = ImagePicker();

  static const List<String> _statusOptions = <String>[
    'Pending',
    'Dispatched',
    'In Transit',
    'Delivered',
    'Failed',
  ];

  static final DateFormat _timelineDateFormatter = DateFormat('dd MMM');
  static final DateFormat _timelineWeekdayFormatter = DateFormat('E');

  String _deliveryStatus = 'Pending';
  bool _showSuccess = false;
  bool _isSubmitting = false;

  String? _lastSubmittedCustomer;
  String? _lastSubmittedPartId;
  String? _lastSubmittedStatus;

  int _activeTimelineIndex = 0;

  final List<_TimelineStep> _timelineSteps = const <_TimelineStep>[
    _TimelineStep(label: 'Schedule', description: 'Confirm delivery window'),
    _TimelineStep(label: 'Preparation', description: 'Assign vehicle & driver'),
    _TimelineStep(label: 'Dispatched', description: 'Load and send out delivery'),
    _TimelineStep(label: 'Tracking', description: 'Monitor in-transit status'),
    _TimelineStep(label: 'Delivered', description: 'Capture POD confirmation'),
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickDeliveryProof() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _deliveryProofImage = File(image.path));
    }
  }

  Future<void> _submitDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, String> deliveryData = <String, String>{
      'customerName': _customerNameController.text,
      'customerId': _customerIdController.text,
      'deliveryAddress': _deliveryAddressController.text,
      'partId': _partIdController.text,
      'vehicleDetails': _vehicleDetailsController.text,
      'driverName': _driverNameController.text,
      'driverContact': _driverContactController.text,
      'scheduledDate': _selectedDate.toIso8601String(),
      'scheduledTime': _selectedTime.format(context),
      'deliveryStatus': _deliveryStatus,
      'remarks': _remarksController.text,
    };

    final String submittedCustomer = _customerNameController.text;
    final String submittedPart = _partIdController.text;
    final String submittedStatus = _deliveryStatus;

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> result = await ApiService.createDelivery(
        deliveryData,
        proofImage: _deliveryProofImage,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _customerNameController.clear();
        _customerIdController.clear();
        _deliveryAddressController.clear();
        _vehicleDetailsController.clear();
        _driverNameController.clear();
        _driverContactController.clear();
        _partIdController.clear();
        _remarksController.clear();

        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
          _lastSubmittedCustomer = submittedCustomer.isEmpty ? 'Customer' : submittedCustomer;
          _lastSubmittedPartId = submittedPart.isEmpty ? 'Unknown part' : submittedPart;
          _lastSubmittedStatus = submittedStatus;
          _deliveryStatus = 'Pending';
          _selectedDate = DateTime.now();
          _selectedTime = TimeOfDay.now();
          _deliveryProofImage = null;
          _activeTimelineIndex = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery record saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isSubmitting = false);

        final String message = result['message']?.toString() ?? 'Failed to save delivery record';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save delivery record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Dispatched':
        return const Color(0xFF38BDF8);
      case 'In Transit':
        return const Color(0xFF34D399);
      case 'Delivered':
        return const Color(0xFF22C55E);
      case 'Failed':
        return const Color(0xFFE11D48);
      case 'Pending':
      default:
        return const Color(0xFF6366F1);
    }
  }

  void _updateTimelineFromStatus(String status) {
    switch (status) {
      case 'Pending':
        _activeTimelineIndex = 0;
        break;
      case 'Dispatched':
        _activeTimelineIndex = 2;
        break;
      case 'In Transit':
        _activeTimelineIndex = 3;
        break;
      case 'Delivered':
        _activeTimelineIndex = 4;
        break;
      case 'Failed':
        _activeTimelineIndex = 4;
        break;
      default:
        _activeTimelineIndex = 0;
    }
  }

  String _formatTimelineDate(DateTime date) => _timelineDateFormatter.format(date);
  String _formatTimelineWeekday(DateTime date) => _timelineWeekdayFormatter.format(date);

  @override
  void initState() {
    super.initState();
    _updateTimelineFromStatus(_deliveryStatus);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerIdController.dispose();
    _deliveryAddressController.dispose();
    _vehicleDetailsController.dispose();
    _driverNameController.dispose();
    _driverContactController.dispose();
    _partIdController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Delivery Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _GlassIconButton(
              icon: Icons.logout_rounded,
              onTap: () async {
                await ApiService.removeToken();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<LoginScreen>(
                    builder: (BuildContext context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          const _AnimatedBackdrop(),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                20,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHeaderCard(theme),
                  const SizedBox(height: 24),
                  _buildDeliveryForm(theme),
                  const SizedBox(height: 32),
                  _buildTimeline(theme),
                ],
              ),
            ),
          ),
          if (_showSuccess) _buildSuccessOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final TextStyle titleStyle = theme.textTheme.titleMedium!.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    final TextStyle captionStyle = theme.textTheme.bodySmall!.copyWith(
      color: Colors.white70,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF1E40AF),
                Color(0xFF2563EB),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.25),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Last Mile Excellence', style: titleStyle),
                        const SizedBox(height: 8),
                        Text(
                          'Keep your delivery commitments on track with real-time visibility and modern reporting.',
                          style: captionStyle.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  _HeaderBadge(
                    icon: Icons.calendar_today,
                    label: 'Scheduled',
                    value: DateFormat('dd MMM').format(_selectedDate),
                  ),
                  const SizedBox(width: 16),
                  _HeaderBadge(
                    icon: Icons.access_time,
                    label: 'Time Window',
                    value: _selectedTime.format(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: -48,
          top: -48,
          child: _FrostedOrb(
            diameter: 160,
            colors: <Color>[
              Colors.white.withOpacity(0.28),
              Colors.white.withOpacity(0.04),
            ],
          ),
        ),
        Positioned(
          left: -60,
          bottom: -60,
          child: _FrostedOrb(
            diameter: 200,
            colors: <Color>[
              Colors.white.withOpacity(0.18),
              Colors.transparent,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryForm(ThemeData theme) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.black.withOpacity(0.08),
      ),
    );

    InputDecoration decoration({
      required String label,
      IconData? icon,
      String? hint,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(
                icon,
                color: const Color(0xFF4C51BF),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
            color: Colors.white.withOpacity(0.78),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _FormSectionTitle(title: 'Customer details'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: decoration(
                      label: 'Customer Name *',
                      icon: Icons.account_circle_rounded,
                      hint: 'e.g., Acme Components Pvt Ltd',
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customerIdController,
                    decoration: decoration(
                      label: 'Customer ID',
                      icon: Icons.badge_outlined,
                      hint: 'Optional internal reference',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FormSectionTitle(title: 'Delivery information'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deliveryAddressController,
                    decoration: decoration(
                      label: 'Delivery Address *',
                      icon: Icons.location_on_outlined,
                      hint: 'Complete shipping destination',
                    ),
                    maxLines: 3,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter delivery address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _partIdController,
                    decoration: decoration(
                      label: 'Part / Order ID *',
                      icon: Icons.qr_code_rounded,
                      hint: 'Unique reference for this dispatch',
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter part or order ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _vehicleDetailsController,
                    decoration: decoration(
                      label: 'Vehicle Details *',
                      icon: Icons.local_shipping_outlined,
                      hint: 'e.g., Truck TN01AB1234, Container 20ft',
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter vehicle details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _driverNameController,
                          decoration: decoration(
                            label: 'Driver Name *',
                            icon: Icons.person_outline,
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _driverContactController,
                          decoration: decoration(
                            label: 'Driver Contact *',
                            icon: Icons.phone_outlined,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _FormSectionTitle(title: 'Schedule & status'),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: _GlassSelectField(
                            icon: Icons.calendar_month_rounded,
                            label: 'Dispatch date',
                            value: DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context),
                          child: _GlassSelectField(
                            icon: Icons.schedule_rounded,
                            label: 'Time window',
                            value: _selectedTime.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _deliveryStatus,
                        isExpanded: true,
                        icon: const Icon(Icons.expand_more_rounded),
                        borderRadius: BorderRadius.circular(16),
                        items: _statusOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _statusColor(value),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(value,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          setState(() {
                            _deliveryStatus = newValue;
                            _updateTimelineFromStatus(newValue);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FormSectionTitle(title: 'Proof of delivery'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDeliveryProof,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                        color: Colors.white,
                      ),
                      child: _deliveryProofImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                _deliveryProofImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 36,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to capture delivery proof',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Attach recipient signature or delivery photo',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.45),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FormSectionTitle(title: 'Additional notes'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: decoration(
                      label: 'Special instructions / remarks',
                      hint: 'Any additional context the driver should know',
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDelivery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save delivery record',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    final DateTime today = DateTime.now();
    final List<DateTime> nextFiveDays = List<DateTime>.generate(
      5,
      (int index) => today.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const _FormSectionTitle(title: 'Delivery cadence'),
            Text(
              'Auto-updates with status',
              style: theme.textTheme.bodySmall!.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: nextFiveDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final DateTime date = nextFiveDays[index];
              final bool isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF2563EB),
                              Color(0xFF1D4ED8),
                            ],
                          )
                        : const LinearGradient(colors: <Color>[Colors.white, Colors.white]),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.black.withOpacity(0.08),
                    ),
                    boxShadow: isSelected
                        ? <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _formatTimelineWeekday(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimelineDate(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        Column(
          children: List<Widget>.generate(_timelineSteps.length, (int index) {
            final _TimelineStep step = _timelineSteps[index];
            final bool isCompleted = index <= _activeTimelineIndex;

            return Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isCompleted ? const Color(0xFF22C55E) : Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF22C55E)
                                  : Colors.black.withOpacity(0.12),
                              width: 3,
                            ),
                          ),
                        ),
                        if (index < _timelineSteps.length - 1)
                          Container(
                            width: 2,
                            height: 42,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isCompleted
                                    ? const <Color>[
                                        Color(0xFF22C55E),
                                        Color(0xFF4ADE80),
                                      ]
                                    : <Color>[Colors.black.withOpacity(0.08), Colors.black.withOpacity(0.05)],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: isCompleted
                              ? const Color(0xFFE5F9E9)
                              : Colors.white.withOpacity(0.92),
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFF86EFAC)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              step.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isCompleted
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.description,
                              style: TextStyle(
                                color: const Color(0xFF111827).withOpacity(0.66),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSuccessOverlay(ThemeData theme) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              const Color(0xFF3A3985).withOpacity(0.9),
              const Color(0xFF2563EB).withOpacity(0.88),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedScale(
            scale: _showSuccess ? 1 : 0.8,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.28),
                    blurRadius: 42,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Color(0xFF22C55E),
                          Color(0xFF16A34A),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Delivery Recorded',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_lastSubmittedCustomer ?? 'Customer'} (${_lastSubmittedPartId ?? 'Part'}) marked as ${_lastSubmittedStatus ?? 'Pending'}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _showSuccess = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final String description;

  const _TimelineStep({required this.label, required this.description});
}

class _FormSectionTitle extends StatelessWidget {
  final String title;

  const _FormSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GlassSelectField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GlassSelectField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        color: Colors.white,
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackdrop extends StatefulWidget {
  const _AnimatedBackdrop();

  @override
  State<_AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<_AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          children: <Widget>[
            Positioned(
              top: -140 + (40 * _controller.value),
              left: -80,
              child: _FrostedOrb(
                diameter: 300,
                colors: <Color>[
                  const Color(0xFF6366F1).withOpacity(0.22),
                  const Color(0xFF2563EB).withOpacity(0.08),
                ],
              ),
            ),
            Positioned(
              bottom: -160 + (30 * (1 - _controller.value)),
              right: -100,
              child: _FrostedOrb(
                diameter: 360,
                colors: <Color>[
                  const Color(0xFF22D3EE).withOpacity(0.18),
                  const Color(0xFF2563EB).withOpacity(0.06),
                ],
              ),
            ),
          ],
        );
      },
    );
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