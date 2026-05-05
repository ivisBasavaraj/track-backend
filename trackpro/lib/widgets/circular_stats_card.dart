import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../ui/app_theme.dart';

class CircularStatsCard extends StatelessWidget {
  final String title;
  final String totalAmount;
  final String totalLabel;
  final List<StatSegment> segments;

  const CircularStatsCard({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.totalLabel,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    _buildIconButton(Icons.calendar_today_outlined),
                    const SizedBox(width: 6),
                    _buildIconButton(Icons.more_vert),
                  ],
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            isMobile
                ? Column(
                    children: [
                      _buildChart(),
                      const SizedBox(height: 16),
                      _buildStatsList(),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildChart()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildStatsList()),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: Colors.grey.shade600),
    );
  }

  Widget _buildChart() {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _CircularChartPainter(segments),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                totalAmount,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsList() {
    return Column(
      children: segments.map((segment) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: segment.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                segment.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 1,
                  child: CustomPaint(
                    painter: _DottedLinePainter(),
                  ),
                ),
              ),
              Text(
                segment.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class StatSegment {
  final String label;
  final String value;
  final double percentage;
  final Color color;

  StatSegment({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });
}

class _CircularChartPainter extends CustomPainter {
  final List<StatSegment> segments;

  _CircularChartPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.8;
    final strokeWidth = 16.0;

    double startAngle = -math.pi / 2;

    for (var segment in segments) {
      if (segment.percentage > 0) {
        final sweepAngle = 2 * math.pi * (segment.percentage / 100);
        final paint = Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );

        startAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    double dashWidth = 3;
    double dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
