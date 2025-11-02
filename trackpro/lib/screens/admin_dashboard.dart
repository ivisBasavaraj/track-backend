import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../services/api_service.dart';
import '../ui/app_theme.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_dashboard.dart';
import '../widgets/modern_loading.dart';
import '../widgets/modern_search.dart';
import 'assign_users_screen.dart';
import 'manage_users_screen.dart';
import 'modern_tool_management_screen.dart';
import 'tool_life_dashboard_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String adminName;

  const AdminDashboard({super.key, required this.adminName});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const double _sectionSpacing = 24;

  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  bool _hasError = false;
  int _selectedTabIndex = 0;
  String _searchQuery = '';

  final List<_DashboardTab> _tabs = const [
    _DashboardTab('Overview', Icons.dashboard_customize_outlined),
    _DashboardTab('Operations', Icons.precision_manufacturing_outlined),
    _DashboardTab('Team', Icons.people_alt_outlined),
    _DashboardTab('Activity', Icons.timeline_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final result = await ApiService.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _dashboardData = result;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!refresh) {
          _hasError = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: ModernLoadingIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 12),
              Text(
                'Unable to load dashboard',
                style: AppTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ModernButton(
                text: 'Retry',
                type: ModernButtonType.primary,
                onPressed: () => _loadDashboardData(),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 900;
    final bool isMobile = screenWidth < 600;
    final bool isSmall = screenWidth < 720;
    final double horizontalPadding = isMobile ? 14 : isSmall ? 18 : 24;
    final double topPadding = isMobile ? 14 : 24;
    final double bottomPadding = isMobile ? 20 : 32;
    final double sectionSpacing = isSmall ? 20 : _sectionSpacing;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () => _loadDashboardData(refresh: true),
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTabSelector(isCompact),
                      SizedBox(height: sectionSpacing),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildTabContent(_selectedTabIndex, screenWidth),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    final todayOverview = _dashboardData['todayOverview'] as Map<String, dynamic>? ?? {};
    final totalUnits = _asNum(todayOverview['totalUnits']).toInt();
    final qualityRate = _asNum(todayOverview['qualityRate']).toStringAsFixed(1);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
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
                AppTheme.primaryColor.withOpacity(0.85),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
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
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.adminName,
                            style: AppTheme.displaySmall.copyWith(
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildSummaryChip(
                      label: 'Total Units Today',
                      value: totalUnits.toString(),
                      icon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryChip(
                      label: 'Quality Rate',
                      value: '$qualityRate%',
                      icon: Icons.verified_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: ModernSearchBar(
            hintText: 'Search activity, tools, or users...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            suggestions: const [
              'Tool maintenance',
              'Quality report',
              'User performance',
              'Delivery status',
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(bool isCompact) {
    Widget buildTabButton(int index) {
      final tab = _tabs[index];
      final isSelected = index == _selectedTabIndex;

      return GestureDetector(
        onTap: () {
          if (_selectedTabIndex != index) {
            setState(() {
              _selectedTabIndex = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                tab.title,
                style: AppTheme.bodyMedium.copyWith(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: isCompact
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++) ...[
                    if (i != 0) const SizedBox(width: 8),
                    SizedBox(width: 160, child: buildTabButton(i)),
                  ],
                ],
              ),
            )
          : Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(child: buildTabButton(i)),
              ],
            ),
    );
  }

  Widget _buildTabContent(int index, double screenWidth) {
    switch (index) {
      case 0:
        return _buildOverviewTab(screenWidth);
      case 1:
        return _buildOperationsTab(screenWidth);
      case 2:
        return _buildTeamTab(screenWidth);
      case 3:
        return _buildActivityTab(screenWidth);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab(double screenWidth) {
    final bool isTablet = screenWidth < 1024;
    final bool isMobile = screenWidth < 680;
    final double spacing = isMobile ? 18 : isTablet ? 22 : _sectionSpacing;

    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 350),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 24,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            ModernDashboardStats(
              stats: _buildStats(),
              crossAxisCount: isMobile ? 1 : isTablet ? 2 : 4,
              crossAxisSpacing: isMobile ? 12 : isTablet ? 14 : 16,
              mainAxisSpacing: isMobile ? 12 : isTablet ? 14 : 16,
            ),
            SizedBox(height: spacing),
            _buildTeamOverviewCard(isMobile),
            SizedBox(height: spacing),
            _buildActivityList(limit: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsTab(double screenWidth) {
    final operations = _buildOperationData();
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 350),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 24,
            child: FadeInAnimation(child: widget),
          ),
          children: operations.map(_buildOperationCard).toList(),
        ),
      ),
    );
  }

  Widget _buildTeamTab(double screenWidth) {
    final teamOverview = _dashboardData['teamOverview'] as Map<String, dynamic>? ?? {};
    final activeUsers = _asNum(teamOverview['activeUsers']).toInt();
    final totalUsers = _asNum(teamOverview['totalUsers']).toInt();
    final efficiency = _asNum(teamOverview['efficiency']).toStringAsFixed(0);

    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 350),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 24,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            _buildTeamOverviewCard(screenWidth < 680),
            const SizedBox(height: _sectionSpacing),
            ModernCard(
              title: 'Team Activity',
              subtitle: 'Live workforce metrics',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatTile('Active Users', activeUsers.toString(), Icons.supervised_user_circle)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatTile('Total Users', totalUsers.toString(), Icons.manage_accounts)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatTile('Efficiency', '$efficiency%', Icons.bolt_outlined)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ModernButton(
                    text: 'Add New User',
                    type: ModernButtonType.secondary,
                    icon: Icons.person_add_outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageUsersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab(double screenWidth) {
    final operations = _buildOperationData();

    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 350),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 24,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            _buildProcessPerformanceSection(operations, screenWidth),
            const SizedBox(height: _sectionSpacing),
            _buildActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessPerformanceSection(List<_OperationCardData> operations, double screenWidth) {
    final bool isTablet = screenWidth < 1024;
    final bool isMobile = screenWidth < 680;
    final int columns = isMobile ? 1 : isTablet ? 2 : 4;
    final double aspectRatio = isMobile ? 2.4 : isTablet ? 1.4 : 1.2;
    final double spacing = isMobile ? 12 : isTablet ? 14 : 18;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: operations.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, index) {
        final operation = operations[index];
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: columns,
          duration: const Duration(milliseconds: 400),
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: _buildProcessStatBlock(operation, isMobile),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessStatBlock(_OperationCardData operation, bool isMobile) {
    final performance = _asNum(operation.data['performance']).clamp(0, 100);
    final metrics = operation.data.entries
        .where((entry) => entry.key.toString() != 'performance')
        .map((metric) => MapEntry(
              _formatKey(metric.key),
              _formatValue(metric.value),
            ))
        .toList();
    final highlight = metrics.isNotEmpty ? metrics.first : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            operation.color.withOpacity(0.9),
            operation.color.withOpacity(0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: operation.color.withOpacity(0.25),
            blurRadius: isMobile ? 16 : 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isMobile ? 38 : 44,
                  height: isMobile ? 38 : 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  ),
                  child: Icon(operation.icon, color: Colors.white, size: isMobile ? 18 : 22),
                ),
                SizedBox(width: isMobile ? 12 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        operation.title,
                        style: (isMobile ? AppTheme.headlineMedium : AppTheme.headlineSmall).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (highlight != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${highlight.value} ${highlight.key}',
                            style: AppTheme.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${performance.toStringAsFixed(0)}%',
                  style: (isMobile ? AppTheme.headlineMedium : AppTheme.headlineSmall).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 14 : 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: performance / 100,
                minHeight: isMobile ? 6 : 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            if (metrics.length > 1)
              Padding(
                padding: EdgeInsets.only(top: isMobile ? 14 : 18),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .skip(1)
                      .map(
                        (metric) => _buildProcessMetricPill(
                          metric.key,
                          metric.value,
                          isMobile,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessMetricPill(String label, String value, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 14, vertical: isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value  ',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 13 : null,
              ),
            ),
            TextSpan(
              text: label,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: isMobile ? 11 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ModernCard _buildTeamOverviewCard(bool isMobile) {
    final teamOverview = _dashboardData['teamOverview'] as Map<String, dynamic>? ?? {};
    final activeUsers = _asNum(teamOverview['activeUsers']).toInt();
    final totalUsers = _asNum(teamOverview['totalUsers']).toInt();
    final efficiency = _asNum(teamOverview['efficiency']).toDouble();

    final metricWidgets = [
      _buildMetricPill('Active Users', activeUsers.toString(), AppTheme.primaryColor, isMobile),
      _buildMetricPill('Total Users', totalUsers.toString(), AppTheme.infoColor, isMobile),
      _buildMetricPill('Efficiency', '${efficiency.toStringAsFixed(0)}%', AppTheme.successColor, isMobile),
    ];

    return ModernCard(
      title: 'Team Overview',
      subtitle: 'Live productivity snapshot',
      child: Column(
        children: [
          if (isMobile)
            Column(
              children: [
                for (var i = 0; i < metricWidgets.length; i++) ...[
                  if (i != 0) const SizedBox(height: 12),
                  metricWidgets[i],
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(child: metricWidgets[0]),
                const SizedBox(width: 12),
                Expanded(child: metricWidgets[1]),
                const SizedBox(width: 12),
                Expanded(child: metricWidgets[2]),
              ],
            ),
          SizedBox(height: isMobile ? 16 : 20),
          LinearProgressIndicator(
            value: efficiency.clamp(0, 100) / 100,
            minHeight: isMobile ? 5 : 6,
            backgroundColor: AppTheme.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList({int? limit}) {
    final activities = _filteredActivities();
    final visibleActivities = limit != null && activities.length > limit
        ? activities.take(limit).toList()
        : activities;

    return ModernCard(
      title: 'Recent Activity',
      subtitle: limit != null ? 'Latest updates across operations' : 'Full activity timeline',
      trailing: limit != null
          ? TextButton(
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 3;
                });
              },
              child: const Text('View All'),
            )
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 540;
          final bool isSingleColumn = constraints.maxWidth < 720;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: visibleActivities.map((activity) {
              final color = _parseColor(activity['color']);
              final icon = _parseIcon(activity['icon']);
              final title = activity['type']?.toString() ?? '';
              final description = activity['description']?.toString() ?? '';
              final time = _formatRelativeTime(activity['time']);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                  child: isSingleColumn
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: AppTheme.headlineSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        time,
                                        style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              description,
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              time,
                              style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
                            ),
                          ],
                        ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  List<DashboardStat> _buildStats() {
    final todayOverview = _dashboardData['todayOverview'] as Map<String, dynamic>? ?? {};

    return [
      DashboardStat(
        title: 'Total Units',
        subtitle: 'Completed today',
        value: _asNum(todayOverview['totalUnits']),
        icon: Icons.inventory_outlined,
        color: AppTheme.primaryColor,
      ),
      DashboardStat(
        title: 'Quality Rate',
        subtitle: 'Inspection success',
        value: _asNum(todayOverview['qualityRate']),
        icon: Icons.verified_outlined,
        color: AppTheme.successColor,
        isDecimal: true,
      ),
      DashboardStat(
        title: 'Active Tasks',
        subtitle: 'Across production',
        value: _asNum(todayOverview['activeTasks']),
        icon: Icons.assignment_outlined,
        color: AppTheme.warningColor,
      ),
      DashboardStat(
        title: 'Deliveries',
        subtitle: 'Dispatched today',
        value: _asNum(todayOverview['deliveries']),
        icon: Icons.local_shipping_outlined,
        color: AppTheme.infoColor,
      ),
    ];
  }

  List<_OperationCardData> _buildOperationData() {
    final operations = _dashboardData['operationsStatus'] as Map<String, dynamic>? ?? {};

    return [
      _OperationCardData(
        title: 'Incoming Inspection',
        icon: Icons.fact_check_outlined,
        color: AppTheme.primaryColor,
        data: Map<String, dynamic>.from(operations['incomingInspection'] ?? {}),
      ),
      _OperationCardData(
        title: 'Finishing',
        icon: Icons.precision_manufacturing_outlined,
        color: AppTheme.warningColor,
        data: Map<String, dynamic>.from(operations['finishing'] ?? {}),
      ),
      _OperationCardData(
        title: 'Quality Control',
        icon: Icons.verified_user_outlined,
        color: AppTheme.successColor,
        data: Map<String, dynamic>.from(operations['qualityControl'] ?? {}),
      ),
      _OperationCardData(
        title: 'Delivery',
        icon: Icons.local_shipping_outlined,
        color: AppTheme.infoColor,
        data: Map<String, dynamic>.from(operations['delivery'] ?? {}),
      ),
    ];
  }

  Widget _buildOperationCard(_OperationCardData operation) {
    final performance = _asNum(operation.data['performance']).toDouble();
    final metrics = operation.data.entries
        .where((entry) => entry.key.toString() != 'performance')
        .map((entry) => MapEntry(_formatKey(entry.key), _formatValue(entry.value)))
        .toList();

    return ModernCard(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: operation.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(operation.icon, color: operation.color, size: 22),
      ),
      title: operation.title,
      subtitle: 'Performance ${performance.toStringAsFixed(0)}%',
      child: Column(
        children: [
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: performance.clamp(0, 100) / 100,
            minHeight: 6,
            backgroundColor: AppTheme.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(operation.color),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map(
                  (metric) => _buildMetricChip(metric.key, metric.value, operation.color.withOpacity(0.15)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value  ',
              style: AppTheme.headlineSmall,
            ),
            TextSpan(
              text: label,
              style: AppTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 16, vertical: isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: (isMobile ? AppTheme.headlineMedium : AppTheme.headlineLarge).copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontSize: isMobile ? 12 : null),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuButton<String> _buildProfileButton() {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Text(
          widget.adminName.isNotEmpty ? widget.adminName[0].toUpperCase() : 'A',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: _handleMenuSelection,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Text('Profile', style: AppTheme.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem<String>(
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
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppTheme.errorColor),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip({required String label, required String value, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTheme.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        Navigator.of(context).pushNamed('/profile');
        break;
      case 'settings':
        Navigator.of(context).pushNamed('/settings');
        break;
      case 'logout':
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        break;
    }
  }

  List<Map<String, dynamic>> _filteredActivities() {
    final rawActivities = _dashboardData['recentActivity'] as List<dynamic>? ?? [];
    final activities = rawActivities
        .whereType<Map<String, dynamic>>()
        .map((activity) => Map<String, dynamic>.from(activity))
        .toList();

    if (_searchQuery.isEmpty) {
      return activities;
    }

    final query = _searchQuery.toLowerCase();
    return activities.where((activity) {
      final title = activity['type']?.toString().toLowerCase() ?? '';
      final description = activity['description']?.toString().toLowerCase() ?? '';
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  double _asNum(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _formatKey(Object key) {
    final text = key.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (i == 0) {
        buffer.write(char.toUpperCase());
      } else if (char.toUpperCase() == char && char != '_') {
        buffer.write(' ');
        buffer.write(char);
      } else if (char == '_') {
        buffer.write(' ');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String _formatValue(dynamic value) {
    if (value is num) {
      return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    }
    if (value is String) {
      return value;
    }
    return value?.toString() ?? '';
  }

  Color _parseColor(dynamic value) {
    final text = value?.toString().toLowerCase() ?? '';
    switch (text) {
      case 'red':
        return AppTheme.errorColor;
      case 'green':
        return AppTheme.successColor;
      case 'orange':
      case 'amber':
        return AppTheme.warningColor;
      case 'blue':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _parseIcon(dynamic value) {
    switch (value) {
      case 'error':
        return Icons.error_outline;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatRelativeTime(dynamic value) {
    DateTime? time;
    if (value is DateTime) {
      time = value;
    } else if (value is String) {
      time = DateTime.tryParse(value);
    }
    if (time == null) {
      return '';
    }
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}

class _DashboardTab {
  final String title;
  final IconData icon;

  const _DashboardTab(this.title, this.icon);
}

class _OperationCardData {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> data;

  const _OperationCardData({
    required this.title,
    required this.icon,
    required this.color,
    required this.data,
  });
}
