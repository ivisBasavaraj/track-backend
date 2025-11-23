// File: lib/screens/modern_admin_dashboard.dart
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
import 'manage_users_screen.dart';
import 'modern_tool_management_screen.dart';
import 'tool_life_dashboard_screen.dart';

class ModernAdminDashboard extends StatefulWidget {
  final String adminName;

  const ModernAdminDashboard({super.key, required this.adminName});

  @override
  State<ModernAdminDashboard> createState() => _ModernAdminDashboardState();
}

class _ModernAdminDashboardState extends State<ModernAdminDashboard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  final List<DashboardTab> _tabs = [
    DashboardTab('Overview', Icons.dashboard_outlined),
    DashboardTab('Production', Icons.precision_manufacturing_outlined),
    DashboardTab('Quality', Icons.verified_outlined),
    DashboardTab('Analytics', Icons.analytics_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final result = await ApiService.getDashboardStats();
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
      'totalUnits': 1250,
      'qualityRate': 97.8,
      'completedTasks': 23,
      'pendingDeliveries': 5,
      'productionEfficiency': 94.2,
      'toolsInUse': 156,
      'activeUsers': 42,
      'systemUptime': 99.7,
      'recentActivities': [
        {
          'title': 'Production Batch #2024-001 Completed',
          'time': '2 hours ago',
          'type': 'success',
        },
        {
          'title': 'Quality Check Alert: Tool #T-456',
          'time': '4 hours ago',
          'type': 'warning',
        },
        {
          'title': 'New User Registration: Sarah Johnson',
          'time': '6 hours ago',
          'type': 'info',
        },
      ],
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
      expandedHeight: 140,
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
                              'Welcome back,',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              widget.adminName,
                              style: AppTheme.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildProfileButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildTabBar(),
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return PopupMenuButton<String>(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Text('Profile', style: AppTheme.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Text('Settings', style: AppTheme.bodyMedium),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppTheme.errorColor),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: _handleMenuAction,
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.title,
                      style: AppTheme.bodySmall.copyWith(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
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
                  _buildSearchSection(),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  _buildRecentActivities(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return ModernSearchBar(
      hintText: 'Search dashboard, tools, users...',
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      suggestions: const [
        'Tool Management',
        'User Analytics',
        'Production Reports',
        'Quality Control',
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final bool isMobile = screenWidth < 600;
        final bool isTablet = screenWidth < 1024;
        final int crossAxisCount = isMobile ? 1 : isTablet ? 2 : 4;

        return ModernDashboardStats(
          stats: [
            DashboardStat(
              title: 'Total Production',
              value: (_dashboardData['totalUnits'] ?? 0),
              subtitle: 'Units completed',
              icon: Icons.precision_manufacturing,
              color: AppTheme.primaryColor,
              trend: const StatTrend(percentage: 12.0, isPositive: true),
            ),
            DashboardStat(
              title: 'Quality Rate',
              value: (_dashboardData['qualityRate'] ?? 0),
              subtitle: 'Quality assurance',
              icon: Icons.verified,
              color: AppTheme.successColor,
              isDecimal: true,
              trend: const StatTrend(percentage: 2.3, isPositive: true),
            ),
            DashboardStat(
              title: 'Active Tools',
              value: (_dashboardData['toolsInUse'] ?? 0),
              subtitle: 'Currently in use',
              icon: Icons.build_circle,
              color: AppTheme.warningColor,
              trend: const StatTrend(percentage: 5.0, isPositive: true),
            ),
            DashboardStat(
              title: 'System Uptime',
              value: (_dashboardData['systemUptime'] ?? 0),
              subtitle: 'Reliability score',
              icon: Icons.trending_up,
              color: AppTheme.infoColor,
              isDecimal: true,
              trend: const StatTrend(percentage: 0.2, isPositive: true),
            ),
          ],
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 12 : isTablet ? 14 : 16,
          mainAxisSpacing: isMobile ? 12 : isTablet ? 14 : 16,
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickAction(
        'Tool Management',
        Icons.precision_manufacturing_outlined,
        AppTheme.primaryColor,
        () => _navigateToToolManagement(),
      ),
      QuickAction(
        'User Management',
        Icons.people_outline,
        AppTheme.successColor,
        () => _navigateToUserManagement(),
      ),
      QuickAction(
        'Reports',
        Icons.analytics_outlined,
        AppTheme.infoColor,
        () => _navigateToReports(),
      ),
      QuickAction(
        'Settings',
        Icons.settings_outlined,
        AppTheme.textSecondary,
        () => _navigateToSettings(),
      ),
    ];

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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return ModernButton(
                text: action.title,
                icon: action.icon,
                onPressed: action.onPressed,
                style: ModernButtonStyle.outline,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = _dashboardData['recentActivities'] ?? [];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activities',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.map<Widget>((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color color;

    switch (activity['type']) {
      case 'success':
        icon = Icons.check_circle_outline;
        color = AppTheme.successColor;
        break;
      case 'warning':
        icon = Icons.warning_outlined;
        color = AppTheme.warningColor;
        break;
      case 'info':
        icon = Icons.info_outline;
        color = AppTheme.infoColor;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppTheme.textSecondary;
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? '',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'] ?? '',
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        // Navigate to profile
        break;
      case 'settings':
        _navigateToSettings();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _navigateToToolManagement() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModernToolManagementScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeInOut),
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ToolLifeDashboardScreen(),
      ),
    );
  }

  void _navigateToSettings() {
    // Implement settings navigation
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ModernButton(
            text: 'Logout',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ModernButtonStyle.danger,
          ),
        ],
      ),
    );
  }
}

class DashboardTab {
  final String title;
  final IconData icon;

  DashboardTab(this.title, this.icon);
}

class QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  QuickAction(this.title, this.icon, this.color, this.onPressed);
}