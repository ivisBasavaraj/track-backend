// File: lib/widgets/modern_dashboard.dart
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../ui/app_theme.dart';
import 'modern_card.dart';

class ModernDashboardStats extends StatelessWidget {
  final List<DashboardStat> stats;
  final int crossAxisCount;
  final double? childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;

  const ModernDashboardStats({
    super.key,
    required this.stats,
    this.crossAxisCount = 2,
    this.childAspectRatio,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final aspectRatio = childAspectRatio ?? (crossAxisCount == 1 ? 2.8 : crossAxisCount == 2 ? 1.25 : 1.1);

    return AnimationLimiter(
      child: GridView.builder(
        padding: padding,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: AppDurations.medium,
            columnCount: crossAxisCount,
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: _StatCard(
                  stat: stats[index],
                  isCompact: crossAxisCount <= 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final DashboardStat stat;
  final bool isCompact;

  const _StatCard({required this.stat, required this.isCompact});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _countAnimation = Tween<double>(
      begin: 0,
      end: widget.stat.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppCurves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radiusValue = widget.isCompact ? 20.0 : 24.0;
    final gradientColors = _buildGradientPalette(widget.stat.color);
    return ModernCard(
      enableShadow: false,
      showBorder: false,
      color: Colors.transparent,
      borderRadius: radiusValue,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(radiusValue),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Transform.translate(
                offset: Offset(radiusValue * 0.7, -radiusValue * 1.1),
                child: Container(
                  width: radiusValue * 3,
                  height: radiusValue * 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Transform.translate(
                offset: Offset(-radiusValue, radiusValue * 0.7),
                child: Container(
                  width: radiusValue * 2.2,
                  height: radiusValue * 2.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: widget.isCompact ? 32 : 40,
                        height: widget.isCompact ? 32 : 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.isCompact ? 8 : 10),
                          color: Colors.white.withOpacity(0.18),
                        ),
                        child: Icon(
                          widget.stat.icon,
                          color: Colors.white,
                          size: widget.isCompact ? 16 : 20,
                        ),
                      ),
                      SizedBox(height: widget.isCompact ? 8 : 10),
                      Text(
                        widget.stat.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelMedium.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: widget.isCompact ? 11 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: widget.isCompact ? 2 : 4),
                      AnimatedBuilder(
                        animation: _countAnimation,
                        builder: (context, child) {
                          final valueText = widget.stat.isDecimal
                              ? _countAnimation.value.toStringAsFixed(1)
                              : _countAnimation.value.toInt().toString();
                          return Text(
                            valueText,
                            textAlign: TextAlign.center,
                            style: (widget.isCompact ? AppTheme.displaySmall : AppTheme.displayMedium).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              fontSize: widget.isCompact ? 22 : 28,
                            ),
                          );
                        },
                      ),
                      if (widget.stat.trend != null || widget.stat.subtitle != null) ...[
                        SizedBox(height: widget.isCompact ? 4 : 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.stat.trend != null) ...[
                                Icon(
                                  widget.stat.trend!.isPositive
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: widget.isCompact ? 12 : 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.stat.trend!.percentage.toStringAsFixed(1)}%',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: widget.isCompact ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.stat.subtitle != null)
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                              if (widget.stat.subtitle != null)
                                Text(
                                  widget.stat.subtitle!,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: widget.isCompact ? 10 : 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _buildGradientPalette(Color baseColor) {
    final start = Color.lerp(baseColor, Colors.white, 0.3)!;
    final end = Color.lerp(baseColor, Colors.black, 0.2)!;
    return [start, end];
  }
}

class ModernQuickActions extends StatelessWidget {
  final List<QuickAction> actions;
  
  const ModernQuickActions({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: AppDurations.medium,
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: actions.map((action) => _QuickActionCard(action: action)).toList(),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final QuickAction action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        onTap: () => action.onTap(context),
        enableHover: true,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    action.color,
                    action.color.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                action.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textTertiary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernAlertCard extends StatelessWidget {
  final List<DashboardAlert> alerts;
  
  const ModernAlertCard({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return ModernCard(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppTheme.successColor,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'All Systems Normal',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No alerts at this time',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ModernCard(
      title: 'System Alerts',
      subtitle: '${alerts.length} active alerts',
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.warningColor,
          size: 20,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...alerts.take(3).map((alert) => _AlertItem(alert: alert)),
          if (alerts.length > 3)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.more_horiz,
                    color: AppTheme.textTertiary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${alerts.length - 3} more alerts',
                    style: AppTheme.labelMedium.copyWith(
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
}

class _AlertItem extends StatelessWidget {
  final DashboardAlert alert;

  const _AlertItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.severity.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alert.severity.color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            alert.severity.icon,
            color: alert.severity.color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTheme.labelLarge.copyWith(
                    color: alert.severity.color,
                  ),
                ),
                if (alert.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    alert.description!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatTimeAgo(alert.timestamp),
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}

// Data Models
class DashboardStat {
  final String title;
  final String? subtitle;
  final num value;
  final IconData icon;
  final Color color;
  final bool isDecimal;
  final StatTrend? trend;

  const DashboardStat({
    required this.title,
    this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    this.isDecimal = false,
    this.trend,
  });
}

class StatTrend {
  final double percentage;
  final bool isPositive;

  const StatTrend({
    required this.percentage,
    required this.isPositive,
  });
}

class QuickAction {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Function(BuildContext) onTap;

  const QuickAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class DashboardAlert {
  final String title;
  final String? description;
  final DateTime timestamp;
  final AlertSeverity severity;

  const DashboardAlert({
    required this.title,
    this.description,
    required this.timestamp,
    required this.severity,
  });
}

enum AlertSeverity {
  info(Icons.info_outline, AppTheme.infoColor),
  warning(Icons.warning_amber_rounded, AppTheme.warningColor),
  error(Icons.error_outline, AppTheme.errorColor),
  critical(Icons.dangerous_outlined, AppTheme.errorColor);

  const AlertSeverity(this.icon, this.color);
  final IconData icon;
  final Color color;
}

class ProcessMetric {
  final String name;
  final Color color;
  final double throughput;
  final double quality;
  final double share;
  final List<double> timeline;

  const ProcessMetric({
    required this.name,
    required this.color,
    required this.throughput,
    required this.quality,
    required this.share,
    required this.timeline,
  });
}

class ProcessAnalyticsPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> timelineLabels;
  final List<ProcessMetric> metrics;

  const ProcessAnalyticsPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timelineLabels,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return ModernCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTheme.bodySmall),
            const SizedBox(height: 16),
            const _EmptyChartState(label: 'No process analytics available'),
          ],
        ),
      );
    }

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;
              if (isCompact) {
                return Column(
                  children: [
                    SizedBox(
                      height: 260,
                      child: _ProcessLineChart(metrics: metrics, timelineLabels: timelineLabels),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: _ProcessPieChart(metrics: metrics),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _ProcessLineChart(metrics: metrics, timelineLabels: timelineLabels)),
                  const SizedBox(width: 24),
                  Expanded(child: _ProcessPieChart(metrics: metrics)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _ProcessLegend(metrics: metrics),
        ],
      ),
    );
  }
}

class _ProcessLineChart extends StatelessWidget {
  final List<ProcessMetric> metrics;
  final List<String> timelineLabels;

  const _ProcessLineChart({required this.metrics, required this.timelineLabels});

  @override
  Widget build(BuildContext context) {
    final sanitizedMetrics = metrics.where((metric) => metric.timeline.isNotEmpty).toList();
    if (sanitizedMetrics.isEmpty) {
      return const _EmptyChartState(label: 'Insufficient data');
    }

    final maxTimelineValue = sanitizedMetrics
        .map((metric) => metric.timeline.reduce(math.max))
        .fold<double>(0, (previousValue, element) => math.max(previousValue, element));
    final double maxY = maxTimelineValue == 0 ? 10.0 : maxTimelineValue * 1.2;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (timelineLabels.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppTheme.borderColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppTheme.borderColor),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.surfaceColor,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final metric = sanitizedMetrics[spot.barIndex];
                final labelIndex = spot.x.toInt();
                final label = labelIndex >= 0 && labelIndex < timelineLabels.length
                    ? timelineLabels[labelIndex]
                    : '';
                return LineTooltipItem(
                  '${metric.name}\n$label: ${spot.y.toStringAsFixed(1)} units',
                  AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= timelineLabels.length) {
                  return const SizedBox.shrink();
                }
                final shouldShow = index == 0 || index == timelineLabels.length - 1 || index % 2 == 0;
                if (!shouldShow) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    timelineLabels[index],
                    style: AppTheme.bodySmall.copyWith(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: AppTheme.bodySmall.copyWith(fontSize: 11, color: AppTheme.textSecondary),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: sanitizedMetrics.map((metric) {
          final spots = metric.timeline.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value);
          }).toList();
          return LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: metric.color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: metric.color.withOpacity(0.08),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProcessPieChart extends StatelessWidget {
  final List<ProcessMetric> metrics;

  const _ProcessPieChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final total = metrics.fold<double>(0, (sum, metric) => sum + metric.share);
    if (total == 0) {
      return const _EmptyChartState(label: 'No breakdown data');
    }

    return PieChart(
      PieChartData(
        sections: metrics.map((metric) {
          final percentage = metric.share / total * 100;
          return PieChartSectionData(
            value: metric.share,
            color: metric.color,
            radius: 80,
            title: '${percentage.toStringAsFixed(0)}%',
            titleStyle: AppTheme.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 48,
      ),
    );
  }
}

class _ProcessLegend extends StatelessWidget {
  final List<ProcessMetric> metrics;

  const _ProcessLegend({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: metrics.map((metric) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: metric.color, borderRadius: BorderRadius.circular(6)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.name, style: AppTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${metric.throughput.toStringAsFixed(0)} units • ${metric.quality.toStringAsFixed(1)}% quality',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  final String label;

  const _EmptyChartState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.backgroundColor,
      ),
      child: Center(
        child: Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
