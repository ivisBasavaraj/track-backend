// File: lib/widgets/modern_dashboard.dart
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
    final aspectRatio = childAspectRatio ?? (crossAxisCount == 1 ? 2.8 : crossAxisCount == 2 ? 1.4 : 1.35);

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
            Padding(
              padding: EdgeInsets.all(widget.isCompact ? 18 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: widget.isCompact ? 42 : 48,
                        height: widget.isCompact ? 42 : 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.isCompact ? 14 : 16),
                          color: Colors.white.withOpacity(0.18),
                        ),
                        child: Icon(
                          widget.stat.icon,
                          color: Colors.white,
                          size: widget.isCompact ? 20 : 22,
                        ),
                      ),
                      const Spacer(),
                      if (widget.stat.trend != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isCompact ? 10 : 12,
                            vertical: widget.isCompact ? 5 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(widget.stat.trend!.isPositive ? 0.24 : 0.18),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.stat.trend!.isPositive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: Colors.white,
                                size: widget.isCompact ? 14 : 16,
                              ),
                              SizedBox(width: widget.isCompact ? 4 : 6),
                              Text(
                                '${widget.stat.trend!.percentage.toStringAsFixed(1)}%',
                                style: AppTheme.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: widget.isCompact ? 12 : 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: widget.isCompact ? 14 : 18),
                  Text(
                    widget.stat.title,
                    style: AppTheme.labelMedium.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 0.4,
                      fontSize: widget.isCompact ? 13 : 14,
                    ),
                  ),
                  SizedBox(height: widget.isCompact ? 6 : 8),
                  AnimatedBuilder(
                    animation: _countAnimation,
                    builder: (context, child) {
                      final valueText = widget.stat.isDecimal
                          ? _countAnimation.value.toStringAsFixed(1)
                          : _countAnimation.value.toInt().toString();
                      return Text(
                        valueText,
                        style: (widget.isCompact ? AppTheme.displaySmall : AppTheme.displayMedium).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      );
                    },
                  ),
                  if (widget.stat.subtitle != null) ...[
                    SizedBox(height: widget.isCompact ? 10 : 12),
                    Text(
                      widget.stat.subtitle!,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: widget.isCompact ? 12 : 13,
                      ),
                    ),
                  ],
                ],
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
              child: Icon(
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
              Icon(
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
        child: Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.warningColor,
          size: 20,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...alerts.take(3).map((alert) => _AlertItem(alert: alert)).toList(),
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
                  Icon(
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