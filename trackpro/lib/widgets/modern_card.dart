// File: lib/widgets/modern_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class ModernCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool enableHover;
  final bool enableShadow;
  final Duration animationDuration;
  final Widget? leading;
  final Widget? trailing;
  final String? title;
  final String? subtitle;
  final bool showBorder;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.onTap,
    this.enableHover = true,
    this.enableShadow = true,
    this.animationDuration = AppDurations.fast,
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
    this.showBorder = true,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.easeInOutQuart,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2,
      end: (widget.elevation ?? 2) + 4,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.easeInOutQuart,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHoverStart() {
    if (!widget.enableHover || widget.onTap == null) return;
    setState(() => _isHovered = true);
    _animationController.forward();
  }

  void _handleHoverEnd() {
    if (!widget.enableHover || widget.onTap == null) return;
    setState(() => _isHovered = false);
    if (!_isPressed) _animationController.reverse();
  }

  void _handleTapDown() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    if (!_isHovered) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_isHovered) _animationController.reverse();
      });
    }
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    if (!_isHovered) _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin ?? const EdgeInsets.all(8),
            child: Material(
              elevation: widget.enableShadow ? _elevationAnimation.value : 0,
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
              shadowColor: AppTheme.primaryColor.withOpacity(0.1),
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: widget.onTap != null ? (_) => _handleTapDown() : null,
                onTapUp: widget.onTap != null ? (_) => _handleTapUp() : null,
                onTapCancel: widget.onTap != null ? _handleTapCancel : null,
                onHover: widget.enableHover && widget.onTap != null
                    ? (hovering) => hovering ? _handleHoverStart() : _handleHoverEnd()
                    : null,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color ?? AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
                    border: widget.showBorder
                        ? Border.all(
                            color: AppTheme.borderColor,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null || widget.leading != null || widget.trailing != null)
                        _buildHeader(),
                      Flexible(
                        child: Padding(
                          padding: widget.padding ?? const EdgeInsets.all(16),
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: AppTheme.headlineMedium,
                  ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 12),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final double opacity;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.opacity = 0.1,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        color: (backgroundColor ?? Colors.white).withOpacity(opacity),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: blur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}