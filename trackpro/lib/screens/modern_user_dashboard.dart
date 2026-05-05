// File: lib/screens/modern_user_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../ui/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_loading.dart';

class ModernUserDashboard extends StatefulWidget {
  final String userName;
  final String userRole;

  const ModernUserDashboard({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<ModernUserDashboard> createState() => _ModernUserDashboardState();
}

class _ModernUserDashboardState extends State<ModernUserDashboard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  List<Task> _todayTasks = [];
  List<Notification> _notifications = [];
  Map<String, dynamic> _userStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _initializeSampleData();
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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _initializeSampleData() {
    _todayTasks = [
      Task(
        id: 'T001',
        title: 'Quality Check - Batch #001',
        description: 'Inspect components for defects and measurements',
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        dueTime: DateTime.now().add(const Duration(hours: 2)),
        estimatedDuration: 90,
      ),
      Task(
        id: 'T002',
        title: 'Tool Setup - CNC Machine',
        description: 'Configure cutting tools for production run',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        dueTime: DateTime.now().add(const Duration(hours: 4)),
        estimatedDuration: 45,
      ),
      Task(
        id: 'T003',
        title: 'Documentation Update',
        description: 'Update work order completion reports',
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        dueTime: DateTime.now().add(const Duration(hours: 6)),
        estimatedDuration: 30,
      ),
    ];

    _notifications = [
      Notification(
        id: 'N001',
        title: 'Break Time Reminder',
        message: 'Your scheduled break is in 15 minutes',
        type: NotificationType.info,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Notification(
        id: 'N002',
        title: 'Safety Alert',
        message: 'Remember to wear protective equipment in Area C',
        type: NotificationType.warning,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Notification(
        id: 'N003',
        title: 'Task Completed',
        message: 'Great job! You completed inspection task T-456',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    _userStats = {
      'tasksCompleted': 24,
      'tasksRemaining': 3,
      'hoursWorked': 6.5,
      'efficiency': 94.2,
      'qualityScore': 98.5,
      'safetyScore': 100.0,
    };
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Simulate loading
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
      expandedHeight: 200,
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              widget.userName,
                              style: AppTheme.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.userRole,
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildNotificationBell(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white),
            if (_notifications.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_notifications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          _showNotificationsBottomSheet();
        },
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
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildTodayTasks(),
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

  Widget _buildStatsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 400 ? 1 : 2;
    final aspectRatio = screenWidth < 400 ? 2.5 : 1.5;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Tasks Completed',
          '${_userStats['tasksCompleted']}',
          Icons.check_circle,
          AppTheme.successColor,
        ),
        _buildStatCard(
          'Tasks Remaining',
          '${_userStats['tasksRemaining']}',
          Icons.pending_actions,
          AppTheme.warningColor,
        ),
        _buildStatCard(
          'Quality Score',
          '${_userStats['qualityScore']}%',
          Icons.verified,
          AppTheme.infoColor,
        ),
        _buildStatCard(
          'Safety Score',
          '${_userStats['safetyScore']}%',
          Icons.security,
          AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasks() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Tasks',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_todayTasks.where((t) => t.status == TaskStatus.completed).length}/${_todayTasks.length}',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._todayTasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    Color priorityColor;
    Color statusColor;
    IconData statusIcon;

    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = AppTheme.errorColor;
        break;
      case TaskPriority.medium:
        priorityColor = AppTheme.warningColor;
        break;
      case TaskPriority.low:
        priorityColor = AppTheme.infoColor;
        break;
    }

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.inProgress:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.play_circle;
        break;
      case TaskStatus.pending:
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.radio_button_unchecked;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _updateTaskStatus(task);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: task.status == TaskStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.estimatedDuration} min',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(task.dueTime),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                      text: 'Start Task',
                      icon: Icons.play_circle_filled,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                      },
                      style: ModernButtonStyle.primary,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    ModernButton(
                      text: 'Report Issue',
                      icon: Icons.report_problem,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      style: ModernButtonStyle.outline,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    ModernButton(
                      text: 'Break Time',
                      icon: Icons.coffee,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      style: ModernButtonStyle.secondary,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    ModernButton(
                      text: 'End Shift',
                      icon: Icons.logout,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      style: ModernButtonStyle.outline,
                      isExpanded: true,
                    ),
                  ],
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ModernButton(
                      text: 'Start Task',
                      icon: Icons.play_circle_filled,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                      },
                      style: ModernButtonStyle.primary,
                    ),
                    ModernButton(
                      text: 'Report Issue',
                      icon: Icons.report_problem,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      style: ModernButtonStyle.outline,
                    ),
                    ModernButton(
                      text: 'Break Time',
                      icon: Icons.coffee,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      style: ModernButtonStyle.secondary,
                    ),
                    ModernButton(
                      text: 'End Shift',
                      icon: Icons.logout,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      style: ModernButtonStyle.outline,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(_notifications[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Notification notification) {
    Color typeColor;
    IconData typeIcon;

    switch (notification.type) {
      case NotificationType.success:
        typeColor = AppTheme.successColor;
        typeIcon = Icons.check_circle;
        break;
      case NotificationType.warning:
        typeColor = AppTheme.warningColor;
        typeIcon = Icons.warning;
        break;
      case NotificationType.error:
        typeColor = AppTheme.errorColor;
        typeIcon = Icons.error;
        break;
      case NotificationType.info:
        typeColor = AppTheme.infoColor;
        typeIcon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateTaskStatus(Task task) {
    setState(() {
      if (task.status == TaskStatus.pending) {
        task.status = TaskStatus.inProgress;
      } else if (task.status == TaskStatus.inProgress) {
        task.status = TaskStatus.completed;
        _userStats['tasksCompleted'] += 1;
        _userStats['tasksRemaining'] -= 1;
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  TaskStatus status;
  final DateTime dueTime;
  final int estimatedDuration;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueTime,
    required this.estimatedDuration,
  });
}

class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

enum TaskPriority { high, medium, low }
enum TaskStatus { pending, inProgress, completed }
enum NotificationType { success, warning, error, info }