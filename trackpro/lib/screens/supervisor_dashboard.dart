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

  final List<_DeliveryPerformance> _deliveryPerformance = const [
    _DeliveryPerformance(label: 'Mon', committed: 24, delivered: 22),
    _DeliveryPerformance(label: 'Tue', committed: 20, delivered: 18),
    _DeliveryPerformance(label: 'Wed', committed: 28, delivered: 26),
    _DeliveryPerformance(label: 'Thu', committed: 32, delivered: 29),
    _DeliveryPerformance(label: 'Fri', committed: 30, delivered: 28),
    _DeliveryPerformance(label: 'Sat', committed: 18, delivered: 17),
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final toolLists = await _toolsService.getAllToolLists(limit: 100);
      final alertsData = await ApiService.getActiveToolAlerts();
      
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
      title: 'Assign Supervisors',
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



  final List<_TeamActivityData> _teamUpdates = const [
    _TeamActivityData(
      name: 'Akhil Sharma',
      role: 'Tool Room Lead',
      status: 'Completed CSV validation for KMC323HA11.',
      timestamp: '12 min ago',
    ),
    _TeamActivityData(
      name: 'Divya Patel',
      role: 'Quality Supervisor',
      status: 'Flagged 2 lots for re-inspection.',
      timestamp: '45 min ago',
    ),
    _TeamActivityData(
      name: 'Manoj Verma',
      role: 'Dispatch Coordinator',
      status: 'Scheduled delivery for AQP-42 batch.',
      timestamp: '2 hrs ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 260,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: const [
        _LegendIndicator(color: Color(0xFF3B82F6), label: 'Committed loads'),
        _LegendIndicator(color: Color(0xFF22C55E), label: 'Delivered loads'),
      ],
    );
  }

  Widget _buildDeliveryBarChart() {
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
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFFE2E8F0),
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
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        Row(
          children: [
            const _FrostedIconButton(icon: Icons.search),
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
                value: '92%',
              ),
              const SizedBox(width: 16),
              _HeroBadge(
                icon: Icons.schedule_rounded,
                label: 'Next milestone',
                value: '14:30 hrs',
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
        childAspectRatio: 1.35,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _kpiCards.length,
      itemBuilder: (context, index) {
        final card = _kpiCards[index];
        return Container(
          decoration: BoxDecoration(
            color: card.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card.accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(card.icon, color: card.accentColor, size: 24),
              ),
              Text(
                card.value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.trendLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1F2937).withOpacity(0.6),
                    ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final action in _quickActions) ...[
            _QuickActionCard(data: action),
            const SizedBox(width: 16),
          ],
        ],
      ),
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
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFF3A3985)),
            const SizedBox(width: 10),
            const Text('Tool Life Alerts'),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
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

class _FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _FrostedIconButton({
    required this.icon,
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
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white),
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
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.notifications_none_outlined, color: Colors.white),
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