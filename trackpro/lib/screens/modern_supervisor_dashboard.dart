// File: lib/screens/modern_supervisor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../ui/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_dashboard.dart';
import '../widgets/modern_search.dart';
import '../widgets/modern_loading.dart';
import '../services/api_service.dart';

class ModernSupervisorDashboard extends StatefulWidget {
  final String supervisorName;

  const ModernSupervisorDashboard({super.key, required this.supervisorName});

  @override
  State<ModernSupervisorDashboard> createState() => _ModernSupervisorDashboardState();
}

class _ModernSupervisorDashboardState extends State<ModernSupervisorDashboard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  int _selectedShift = 0;
  
  final List<String> _shifts = ['Day Shift', 'Night Shift', 'Weekend Shift'];
  final List<WorkStation> _workStations = [];
  final List<String> _processTimelineLabels = const ['06h', '08h', '10h', '12h', '14h', '16h', '18h'];

  static const List<List<ProcessMetric>> _shiftProcessDefaults = <List<ProcessMetric>>[
    <ProcessMetric>[
      ProcessMetric(
        name: 'Forging',
        color: AppTheme.primaryColor,
        throughput: 180,
        quality: 97.4,
        share: 28,
        timeline: <double>[42, 46, 50, 55, 60, 62, 65],
      ),
      ProcessMetric(
        name: 'Machining',
        color: AppTheme.successColor,
        throughput: 210,
        quality: 96.1,
        share: 33,
        timeline: <double>[48, 52, 57, 60, 64, 68, 72],
      ),
      ProcessMetric(
        name: 'Inspection',
        color: AppTheme.infoColor,
        throughput: 120,
        quality: 99.2,
        share: 18,
        timeline: <double>[60, 62, 64, 66, 68, 70, 72],
      ),
      ProcessMetric(
        name: 'Packaging',
        color: AppTheme.warningColor,
        throughput: 140,
        quality: 97.0,
        share: 21,
        timeline: <double>[30, 34, 36, 40, 44, 48, 51],
      ),
    ],
    <ProcessMetric>[
      ProcessMetric(
        name: 'Forging',
        color: AppTheme.primaryColor,
        throughput: 150,
        quality: 96.2,
        share: 30,
        timeline: <double>[38, 40, 42, 45, 48, 50, 52],
      ),
      ProcessMetric(
        name: 'Machining',
        color: AppTheme.successColor,
        throughput: 170,
        quality: 95.4,
        share: 28,
        timeline: <double>[44, 46, 48, 50, 54, 56, 58],
      ),
      ProcessMetric(
        name: 'Inspection',
        color: AppTheme.infoColor,
        throughput: 100,
        quality: 98.4,
        share: 16,
        timeline: <double>[58, 59, 60, 61, 62, 63, 64],
      ),
      ProcessMetric(
        name: 'Packaging',
        color: AppTheme.warningColor,
        throughput: 130,
        quality: 96.8,
        share: 26,
        timeline: <double>[28, 30, 32, 34, 37, 39, 41],
      ),
    ],
    <ProcessMetric>[
      ProcessMetric(
        name: 'Forging',
        color: AppTheme.primaryColor,
        throughput: 110,
        quality: 95.8,
        share: 26,
        timeline: <double>[32, 34, 36, 38, 41, 43, 45],
      ),
      ProcessMetric(
        name: 'Machining',
        color: AppTheme.successColor,
        throughput: 140,
        quality: 95.0,
        share: 30,
        timeline: <double>[36, 38, 40, 42, 45, 48, 50],
      ),
      ProcessMetric(
        name: 'Inspection',
        color: AppTheme.infoColor,
        throughput: 90,
        quality: 98.0,
        share: 20,
        timeline: <double>[55, 56, 57, 58, 59, 60, 61],
      ),
      ProcessMetric(
        name: 'Packaging',
        color: AppTheme.warningColor,
        throughput: 120,
        quality: 96.2,
        share: 24,
        timeline: <double>[24, 26, 28, 30, 32, 34, 36],
      ),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
    _initializeWorkStations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
    _fadeController.forward();
    _progressController.forward();
  }

  void _initializeWorkStations() {
    _workStations.addAll([
      WorkStation(
        id: 'WS001',
        name: 'CNC Machine #1',
        status: WorkStationStatus.active,
        operator: 'John Smith',
        currentTask: 'Drilling Operation',
        progress: 0.75,
        efficiency: 94.2,
      ),
      WorkStation(
        id: 'WS002',
        name: 'CNC Machine #2',
        status: WorkStationStatus.idle,
        operator: 'Sarah Johnson',
        currentTask: 'Setup in Progress',
        progress: 0.15,
        efficiency: 88.7,
      ),
      WorkStation(
        id: 'WS003',
        name: 'Quality Check Station',
        status: WorkStationStatus.maintenance,
        operator: 'Mike Wilson',
        currentTask: 'Maintenance',
        progress: 0.0,
        efficiency: 0.0,
      ),
      WorkStation(
        id: 'WS004',
        name: 'Assembly Line #1',
        status: WorkStationStatus.active,
        operator: 'Emma Davis',
        currentTask: 'Component Assembly',
        progress: 0.60,
        efficiency: 96.5,
      ),
    ]);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final result = await ApiService.getSupervisorDashboardStats();
      if (mounted) {
        setState(() {
          _dashboardData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dashboardData = _getDefaultData();
        });
      }
    }
  }

  Map<String, dynamic> _getDefaultData() {
    return {
      'totalOperators': 12,
      'activeOperations': 8,
      'completedTasks': 45,
      'efficiency': 92.3,
      'qualityScore': 96.8,
      'safetyIncidents': 0,
      'productionTarget': 85,
      'actualProduction': 78,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.primaryLight.withOpacity(0.03),
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverFillRemaining(
              child: _isLoading
                  ? const Center(child: ModernLoadingIndicator())
                  : _buildDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Production Dashboard',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Supervisor: ${widget.supervisorName}',
                              style: AppTheme.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildNotificationButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildShiftSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          // Handle notifications
        },
      ),
    );
  }

  Widget _buildShiftSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: _shifts.asMap().entries.map((entry) {
          final index = entry.key;
          final shift = entry.value;
          final isSelected = _selectedShift == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedShift = index;
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    shift,
                    style: AppTheme.bodySmall.copyWith(
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : Colors.white,
                      fontWeight: isSelected 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildProductionStats(),
                  const SizedBox(height: 16),
                  _buildProcessAnalytics(),
                  const SizedBox(height: 16),
                  _buildWorkStationsGrid(),
                  const SizedBox(height: 16),
                  _buildProductionProgress(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductionStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final bool isMobile = screenWidth < 600;
        final bool isTablet = screenWidth < 1024;
        final int crossAxisCount = isMobile ? 2 : isTablet ? 2 : 4;

        return ModernDashboardStats(
          stats: [
            DashboardStat(
              title: 'Active Operations',
              value: (_dashboardData['activeOperations'] ?? 0),
              subtitle: 'Currently running',
              icon: Icons.play_circle_filled,
              color: AppTheme.successColor,
            ),
            DashboardStat(
              title: 'Team Efficiency',
              value: (_dashboardData['efficiency'] ?? 0),
              subtitle: 'Overall performance',
              icon: Icons.trending_up,
              color: AppTheme.primaryColor,
              isDecimal: true,
              trend: const StatTrend(percentage: 3.2, isPositive: true),
            ),
            DashboardStat(
              title: 'Quality Score',
              value: (_dashboardData['qualityScore'] ?? 0),
              subtitle: 'Quality metrics',
              icon: Icons.verified,
              color: AppTheme.infoColor,
              isDecimal: true,
              trend: const StatTrend(percentage: 1.8, isPositive: true),
            ),
            DashboardStat(
              title: 'Safety Days',
              value: (_dashboardData['safetyIncidents'] ?? 0),
              subtitle: 'Incident-free',
              icon: Icons.security,
              color: _dashboardData['safetyIncidents'] == 0
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),
          ],
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 12 : isTablet ? 14 : 16,
          mainAxisSpacing: isMobile ? 12 : isTablet ? 14 : 16,
        );
      },
    );
  }

  Widget _buildProcessAnalytics() {
    final shiftName = _shifts[_selectedShift];
    return ProcessAnalyticsPanel(
      title: '$shiftName Processes',
      subtitle: 'Live throughput and quality tracking for $shiftName',
      timelineLabels: _processTimelineLabels,
      metrics: _getSupervisorProcessMetrics(),
    );
  }

  List<ProcessMetric> _getSupervisorProcessMetrics() {
    final processData = _dashboardData['processMetrics'];
    if (processData is Map<String, dynamic>) {
      final shiftData = processData[_shifts[_selectedShift]] ?? processData[_selectedShift.toString()];
      final parsedShift = _parseProcessMetrics(shiftData);
      if (parsedShift.isNotEmpty) {
        return parsedShift;
      }
    }
    final parsed = _parseProcessMetrics(processData);
    if (parsed.isNotEmpty) {
      return parsed;
    }
    return _shiftProcessDefaults[_selectedShift % _shiftProcessDefaults.length];
  }

  List<ProcessMetric> _parseProcessMetrics(dynamic raw) {
    if (raw is List) {
      final palette = <Color>[
        AppTheme.primaryColor,
        AppTheme.successColor,
        AppTheme.infoColor,
        AppTheme.warningColor,
        AppTheme.secondaryColor,
      ];
      final metrics = <ProcessMetric>[];
      for (final entry in raw.asMap().entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) {
          continue;
        }
        final timelineRaw = value['timeline'] as List<dynamic>?;
        final timeline = timelineRaw != null
            ? timelineRaw.whereType<num>().map((number) => number.toDouble()).toList()
            : <double>[];
        metrics.add(
          ProcessMetric(
            name: value['name']?.toString() ?? 'Process ${entry.key + 1}',
            color: palette[entry.key % palette.length],
            throughput: (value['throughput'] as num?)?.toDouble() ?? 0,
            quality: (value['quality'] as num?)?.toDouble() ?? 0,
            share: (value['share'] as num?)?.toDouble() ?? 0,
            timeline: timeline,
          ),
        );
      }
      return metrics;
    }

    if (raw is Map<String, dynamic>) {
      final metrics = raw['metrics'];
      if (metrics is List) {
        return _parseProcessMetrics(metrics);
      }
    }

    return const [];
  }

  Widget _buildWorkStationsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 1 : screenWidth < 900 ? 2 : 3;
    final aspectRatio = screenWidth < 600 ? 2.5 : 1.5;
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work Stations',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _workStations.length,
            itemBuilder: (context, index) {
              return _buildWorkStationCard(_workStations[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkStationCard(WorkStation station) {
    Color statusColor;
    IconData statusIcon;

    switch (station.status) {
      case WorkStationStatus.active:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.play_circle_filled;
        break;
      case WorkStationStatus.idle:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pause_circle_filled;
        break;
      case WorkStationStatus.maintenance:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.build_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            station.operator,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            station.currentTask,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (station.status == WorkStationStatus.active) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${(station.progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value * station.progress,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 4,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductionProgress() {
    final target = _dashboardData['productionTarget'] ?? 100;
    final actual = _dashboardData['actualProduction'] ?? 80;
    final percentage = (actual / target * 100).clamp(0, 100);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Production Target',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$actual / $target Units',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${percentage.toInt()}%',
                style: AppTheme.headlineMedium.copyWith(
                  color: percentage >= 90 
                      ? AppTheme.successColor 
                      : percentage >= 75 
                          ? AppTheme.warningColor 
                          : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value * (percentage / 100),
                backgroundColor: AppTheme.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 90 
                      ? AppTheme.successColor 
                      : percentage >= 75 
                          ? AppTheme.warningColor 
                          : AppTheme.errorColor,
                ),
                minHeight: 8,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTheme.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    ModernButton(
                      text: 'Assign Task',
                      icon: Icons.assignment_add,
                      onPressed: () {},
                      style: ModernButtonStyle.primary,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    ModernButton(
                      text: 'Tool Stock',
                      icon: Icons.storage,
                      onPressed: () {
                        Navigator.pushNamed(context, '/tool-stock');
                      },
                      style: ModernButtonStyle.outline,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    ModernButton(
                      text: 'Quality Check',
                      icon: Icons.verified_user,
                      onPressed: () {},
                      style: ModernButtonStyle.outline,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    ModernButton(
                      text: 'Reports',
                      icon: Icons.analytics,
                      onPressed: () {},
                      style: ModernButtonStyle.outline,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    ModernButton(
                      text: 'Emergency Stop',
                      icon: Icons.emergency,
                      onPressed: () {},
                      style: ModernButtonStyle.danger,
                      isExpanded: true,
                    ),
                  ],
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ModernButton(
                      text: 'Assign Task',
                      icon: Icons.assignment_add,
                      onPressed: () {},
                      style: ModernButtonStyle.primary,
                    ),
                    ModernButton(
                      text: 'Tool Stock',
                      icon: Icons.storage,
                      onPressed: () {
                        Navigator.pushNamed(context, '/tool-stock');
                      },
                      style: ModernButtonStyle.outline,
                    ),
                    ModernButton(
                      text: 'Quality Check',
                      icon: Icons.verified_user,
                      onPressed: () {},
                      style: ModernButtonStyle.outline,
                    ),
                    ModernButton(
                      text: 'Reports',
                      icon: Icons.analytics,
                      onPressed: () {},
                      style: ModernButtonStyle.outline,
                    ),
                    ModernButton(
                      text: 'Emergency Stop',
                      icon: Icons.emergency,
                      onPressed: () {},
                      style: ModernButtonStyle.danger,
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class WorkStation {
  final String id;
  final String name;
  final WorkStationStatus status;
  final String operator;
  final String currentTask;
  final double progress;
  final double efficiency;

  WorkStation({
    required this.id,
    required this.name,
    required this.status,
    required this.operator,
    required this.currentTask,
    required this.progress,
    required this.efficiency,
  });
}

enum WorkStationStatus {
  active,
  idle,
  maintenance,
}