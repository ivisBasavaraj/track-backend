// File: lib/widgets/modern_loading.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../ui/app_theme.dart';

class ModernLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final LoadingStyle style;

  const ModernLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
    this.style = LoadingStyle.circular,
  });

  @override
  State<ModernLoadingIndicator> createState() => _ModernLoadingIndicatorState();
}

enum LoadingStyle { circular, dots, pulse, wave }

class _ModernLoadingIndicatorState extends State<ModernLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryColor;

    switch (widget.style) {
      case LoadingStyle.circular:
        return _buildCircularLoader(color);
      case LoadingStyle.dots:
        return _buildDotsLoader(color);
      case LoadingStyle.pulse:
        return _buildPulseLoader(color);
      case LoadingStyle.wave:
        return _buildWaveLoader(color);
    }
  }

  Widget _buildCircularLoader(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: widget.strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeCap: StrokeCap.round,
      ),
    );
  }

  Widget _buildDotsLoader(Color color) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size / 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final progress = (_animation.value + index * 0.2) % 1.0;
              final scale = 0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2));
              final opacity = 0.3 + (0.7 * (1 - (progress - 0.5).abs() * 2));

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size / 4,
                  height: widget.size / 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(opacity),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulseLoader(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 0.7 + (0.3 * _animation.value);
        final opacity = 1.0 - _animation.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(opacity * 0.5),
              border: Border.all(
                color: color.withOpacity(opacity),
                width: widget.strokeWidth,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveLoader(Color color) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final progress = (_animation.value + index * 0.15) % 1.0;
              final height = widget.size * (0.3 + 0.7 * progress);

              return Container(
                width: widget.size / 8,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.size / 16),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: baseColor ?? AppTheme.borderColor.withOpacity(0.3),
      highlightColor: highlightColor ?? Colors.white.withOpacity(0.8),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;
  final Color backgroundColor;
  final double opacity;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText,
    this.backgroundColor = Colors.black,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor.withOpacity(opacity),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ModernLoadingIndicator(
                      size: 32,
                      style: LoadingStyle.pulse,
                    ),
                    if (loadingText != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingText!,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}