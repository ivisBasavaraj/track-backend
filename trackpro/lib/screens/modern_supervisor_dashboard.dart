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
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: ModernLoadingIndicator())
                : _buildDashboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                              'Production Dashboard',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              'Supervisor: ${widget.supervisorName}',
                              style: AppTheme.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildNotificationButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                decoration: BoxDecoration(
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
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 24),
                  _buildWorkStationsGrid(),
                  const SizedBox(height: 24),
                  _buildProductionProgress(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductionStats() {
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
    );
  }

  Widget _buildWorkStationsGrid() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Work Stations',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ModernButton(
                text: 'View All',
                onPressed: () {},
                style: ModernButtonStyle.outline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  station.name,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            station.operator,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            station.currentTask,
            style: AppTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (station.status == WorkStationStatus.active) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${(station.progress * 100).toInt()}%',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
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
          Wrap(
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