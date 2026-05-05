// File: lib/screens/supervisor_dashboard.dart
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'incoming_inspection_screen.dart';
import 'finishing_screen.dart';
import 'quality_control_screen.dart';
import 'delivery_screen.dart';
import 'assign_users_screen.dart';
import 'tool_list_screen.dart';
import 'tool_management_screen.dart';
import 'modern_tool_management_screen.dart';
import 'tool_stock_management_screen.dart';
import '../services/tools_service.dart';
import '../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class SupervisorDashboard extends StatefulWidget {
  final String supervisorName;

  const SupervisorDashboard({super.key, required this.supervisorName});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final ToolsService _toolsService = ToolsService();
  bool _isLoading = true;
  int _activeToolLists = 0;
  int _totalTools = 0;
  int _totalHoles = 0;
  double _totalCuttingLength = 0.0;
  int _alertCount = 0;
  List<dynamic> _alerts = [];
  List<_DeliveryPerformance> _deliveryPerformance = [];
  List<_TeamActivityData> _teamUpdates = [];
  String _productionScore = '0%';
  String _nextMilestone = '--';
  int _totalUnitsProcessed = 0;
  int _incomingInspection = 0;
  int _finishing = 0;
  int _qualityControl = 0;
  int _delivery = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final toolLists = await _toolsService.getAllToolLists(limit: 100);
      final alertsData = await ApiService.getActiveToolAlerts();
      final supervisorDashboardData = await ApiService.getSupervisorDashboardStats();
      
      _processDashboardData(supervisorDashboardData);
      
      setState(() {
        _activeToolLists = toolLists.length;
        _totalTools = toolLists.fold(0, (sum, tool) => sum + tool.totalTools);
        _totalHoles = toolLists.fold(0, (sum, tool) => sum + tool.totalHoles);
        _totalCuttingLength = toolLists.fold(0.0, (sum, tool) => sum + tool.totalCuttingLength);
        _alerts = alertsData['alerts'] ?? [];
        _alertCount = _alerts.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _processDashboardData(Map<String, dynamic> data) {
    try {
      final processOverview = data['processOverview'] as Map<String, dynamic>? ?? {};
      final processMatrix = data['processMatrix'] as Map<String, dynamic>? ?? {};
      
      _totalUnitsProcessed = (processOverview['totalUnitsProcessed'] ?? 0) as int;
      _incomingInspection = (processOverview['incomingInspection'] ?? 0) as int;
      _finishing = (processOverview['finishing'] ?? 0) as int;
      _qualityControl = (processOverview['qualityControl'] ?? 0) as int;
      _delivery = (processOverview['delivery'] ?? 0) as int;
      
      // Calculate production score from total units
      if (_totalUnitsProcessed > 0) {
        final completedUnits = _delivery;
        _productionScore = '${((completedUnits / _totalUnitsProcessed) * 100).round()}%';
      } else {
        _productionScore = '0%';
      }
      
      if (_delivery > 0) {
        _nextMilestone = '$_delivery pending';
      } else if (_qualityControl > 0) {
        _nextMilestone = '$_qualityControl in QC';
      } else if (_finishing > 0) {
        _nextMilestone = '$_finishing in process';
      } else if (_incomingInspection > 0) {
        _nextMilestone = '$_incomingInspection inspecting';
      } else {
        _nextMilestone = 'All clear';
      }
      
      _generateDeliveryPerformanceData();
      _generateTeamActivityData();
    } catch (e) {
      print('Error processing dashboard data: $e');
    }
  }

  void _generateDeliveryPerformanceData() {
    final now = DateTime.now();
    _deliveryPerformance = [];
    
    for (int i = 6; i >= 1; i--) {
      final date = now.subtract(Duration(days: i));
      final dayLabel = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      
      int committed = ((20 + (i * 2)) + (i % 3) * 5);
      int delivered = ((18 + (i * 2)) + (i % 4) * 3);
      delivered = delivered > committed ? committed : delivered;
      
      _deliveryPerformance.add(
        _DeliveryPerformance(
          label: dayLabel,
          committed: committed,
          delivered: delivered,
        ),
      );
    }
  }

  void _generateTeamActivityData() {
    final now = DateTime.now();
    final timeFormat = (DateTime time) {
      final diff = now.difference(time);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      return '${diff.inDays} days ago';
    };

    _teamUpdates = [
      _TeamActivityData(
        name: 'Incoming Inspection',
        role: 'Quality Check',
        status: _incomingInspection > 0 
            ? 'Completed $_incomingInspection inspections'
            : 'No inspections today',
        timestamp: 'Today',
      ),
      _TeamActivityData(
        name: 'Finishing Process',
        role: 'Production',
        status: _finishing > 0
            ? 'Processed $_finishing components'
            : 'No components processed',
        timestamp: _finishing > 0 ? 'In progress' : 'Idle',
      ),
      _TeamActivityData(
        name: 'Quality Control',
        role: 'QC Status',
        status: _qualityControl > 0
            ? 'Checked $_qualityControl parts'
            : 'No quality checks',
        timestamp: _qualityControl > 0 ? 'Active' : 'Idle',
      ),
      _TeamActivityData(
        name: 'Deliveries',
        role: 'Dispatch',
        status: _delivery > 0
            ? '$_delivery deliveries scheduled'
            : 'No deliveries scheduled',
        timestamp: _delivery > 0 ? 'Pending' : 'Complete',
      ),
    ];
  }

  List<_KpiCardData> get _kpiCards => [
    _KpiCardData(
      title: 'Active Tool Lists',
      value: _isLoading ? '...' : '$_activeToolLists',
      trendLabel: 'Total uploaded',
      icon: Icons.inventory_2_outlined,
      backgroundColor: const Color(0xFFEEF4FF),
      accentColor: const Color(0xFF3B82F6),
    ),
    _KpiCardData(
      title: 'Total Tools',
      value: _isLoading ? '...' : '$_totalTools',
      trendLabel: 'Across all lists',
      icon: Icons.build_outlined,
      backgroundColor: const Color(0xFFFDF2F8),
      accentColor: const Color(0xFFD946EF),
    ),
    _KpiCardData(
      title: 'Total Holes',
      value: _isLoading ? '...' : '$_totalHoles',
      trendLabel: 'In components',
      icon: Icons.circle_outlined,
      backgroundColor: const Color(0xFFFFF7ED),
      accentColor: const Color(0xFFF97316),
    ),
    _KpiCardData(
      title: 'Cutting Length',
      value: _isLoading ? '...' : '${_totalCuttingLength.toStringAsFixed(1)} mm',
      trendLabel: 'Total length',
      icon: Icons.straighten_outlined,
      backgroundColor: const Color(0xFFEFFBF6),
      accentColor: const Color(0xFF0EA5E9),
    ),
  ];

  final List<_QuickActionData> _quickActions = [
    _QuickActionData(
      title: 'Tool Management',
      description: 'Upload and manage tool lists with full control.',
      icon: Icons.settings_outlined,
      backgroundColor: const Color(0xFF3B82F6),
      textColor: Colors.white,
      destinationBuilder: (context) => const ModernToolManagementScreen(),
    ),
    _QuickActionData(
      title: 'Assign Task',
      description: 'Add or reassign supervisors to critical production cells.',
      icon: Icons.person_add_alt,
      backgroundColor: const Color(0xFF1E293B),
      textColor: Colors.white,
      destinationBuilder: (context) => const AssignUsersScreen(),
    ),
    _QuickActionData(
      title: 'Stock Management',
      description: 'Track and manage tool inventory and stock levels.',
      icon: Icons.inventory_outlined,
      backgroundColor: const Color(0xFF10B981),
      textColor: Colors.white,
      destinationBuilder: (context) => const ToolStockManagementScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 24),
              _buildHeroCard(context),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildKpiGrid(),
              const SizedBox(height: 24),
              _buildSectionHeader('Delivery analytics'),
              const SizedBox(height: 12),
              _buildDeliveryLegend(),
              const SizedBox(height: 16),
              _buildDeliveryBarChart(),
              const SizedBox(height: 24),
              _buildSectionHeader('Quick actions'),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildSectionHeader('Team activity'),
              const SizedBox(height: 12),
              _buildTeamActivityList(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryLegend() {
    return const Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _LegendIndicator(color: Color(0xFF3B82F6), label: 'Committed loads'),
        _LegendIndicator(color: Color(0xFF22C55E), label: 'Delivered loads'),
      ],
    );
  }

  Widget _buildDeliveryBarChart() {
    if (_deliveryPerformance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Center(
          child: Text('No delivery data available'),
        ),
      );
    }

    const double borderRadius = 12;
    final bars = _deliveryPerformance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: BarChart(
          BarChartData(
            maxY: _calculateMaxY(bars),
            barGroups: _buildBarGroups(bars, borderRadius),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex >= bars.length) return null;
                  final data = bars[groupIndex];
                  final isDeliveredRod = rodIndex == 1;
                  final value = rod.toY.round();
                  return BarTooltipItem(
                    isDeliveredRod ? 'Delivered: $value' : 'Committed: $value',
                    TextStyle(
                      color: isDeliveredRod
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: '\n${data.label}',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: '\nDelivery score: ${data.deliveryScore.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= bars.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        bars[index].label,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: Color(0xFFE2E8F0),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            groupsSpace: 20,
          ),
        ),
      ),
    );
  }

  double _calculateMaxY(List<_DeliveryPerformance> bars) {
    final double maxValue = bars
        .map((data) => data.committed > data.delivered ? data.committed : data.delivered)
        .fold<double>(0, (previousValue, element) => element > previousValue ? element.toDouble() : previousValue);

    // Provide headroom for visual comfort
    return maxValue + 6;
  }

  List<BarChartGroupData> _buildBarGroups(List<_DeliveryPerformance> data, double radius) {
    final maxY = _calculateMaxY(data);
    return [
      for (int i = 0; i < data.length; i++)
        BarChartGroupData(
          x: i,
          groupVertically: false,
          barsSpace: 12,
          barRods: [
            BarChartRodData(
              toY: data[i].committed.toDouble(),
              color: const Color(0xFF3B82F6),
              width: 16,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: const Color(0xFFE2E8F0),
              ),
            ),
            BarChartRodData(
              toY: data[i].delivered.toDouble(),
              color: const Color(0xFF22C55E),
              width: 16,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
            ),
          ],
        ),
    ];
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _FrostedIconButton(
          icon: Icons.arrow_back,
          iconColor: Colors.black,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        Row(
          children: [
            const _FrostedIconButton(icon: Icons.search, iconColor: Colors.black),
            const SizedBox(width: 12),
            _NotificationButton(
              alertCount: _alertCount,
              onPressed: () => _showAlertsDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, ${widget.supervisorName}',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Here’s a quick overview of today’s operations. Stay on top of tool updates, quality gates, and delivery commitments.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroBadge(
                icon: Icons.auto_graph_rounded,
                label: 'Production score',
                value: _productionScore,
              ),
              const SizedBox(width: 16),
              _HeroBadge(
                icon: Icons.schedule_rounded,
                label: 'Next milestone',
                value: _nextMilestone,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _kpiCards.length,
      itemBuilder: (context, index) {
        final card = _kpiCards[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: card.accentColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: card.accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.icon, color: card.accentColor, size: 16),
              ),
              Text(
                card.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    card.trendLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: const Color(0xFF1F2937).withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _quickActions.length,
      itemBuilder: (context, index) {
        final action = _quickActions[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: action.destinationBuilder),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: action.backgroundColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action.icon,
                    color: action.backgroundColor,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  action.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF64748B).withOpacity(0.9),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamActivityList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: _teamUpdates
            .map(
              (update) => ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                  child: const Icon(Icons.person_outline, color: Color(0xFF1E40AF)),
                ),
                title: Text(
                  update.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      update.status,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  update.timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          'View all',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2563EB).withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  void _showAlertsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF3A3985)),
            SizedBox(width: 10),
            Text('Tool Life Alerts'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _alerts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No active alerts'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    final isCritical = alert['alert_type'] == 'CRITICAL';
                    return Card(
                      color: isCritical ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          isCritical ? Icons.error : Icons.warning,
                          color: isCritical ? Colors.red : Colors.orange,
                          size: 32,
                        ),
                        title: Text(
                          'Tool ${alert['tool_id']} - ${alert['tool_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${alert['alert_type']}: ${alert['usage_percentage'].toStringAsFixed(1)}% used',
                              style: TextStyle(
                                color: isCritical ? Colors.red[700] : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text('Remaining: ${alert['remaining_life']} units'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPerformance {
  final String label;
  final int committed;
  final int delivered;

  const _DeliveryPerformance({
    required this.label,
    required this.committed,
    required this.delivered,
  });

  double get deliveryScore {
    if (committed == 0) {
      return 0;
    }
    return (delivered / committed) * 100;
  }
}

class _LegendIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendIndicator({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.24)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPressed;

  const _FrostedIconButton({
    required this.icon,
    this.iconColor = Colors.white,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int alertCount;
  final VoidCallback onPressed;

  const _NotificationButton({
    required this.alertCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.notifications_none_outlined, color: Colors.black),
          ),
          if (alertCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  alertCount > 9 ? '9+' : '$alertCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.62;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: data.destinationBuilder),
        );
      },
      child: Container(
        width: cardWidth.clamp(280, 360),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: data.backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: data.textColor.withOpacity(data.textColor == Colors.white ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                data.icon,
                color: data.textColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              data.title,
              style: TextStyle(
                color: data.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.description,
              style: TextStyle(
                color: data.textColor.withOpacity(0.78),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Open module',
                  style: TextStyle(
                    color: data.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: data.textColor, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCardData {
  final String title;
  final String value;
  final String trendLabel;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;

  const _KpiCardData({
    required this.title,
    required this.value,
    required this.trendLabel,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
  });
}

class _QuickActionData {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final WidgetBuilder destinationBuilder;

  _QuickActionData({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.destinationBuilder,
  });
}

class _TeamActivityData {
  final String name;
  final String role;
  final String status;
  final String timestamp;

  const _TeamActivityData({
    required this.name,
    required this.role,
    required this.status,
    required this.timestamp,
  });
}