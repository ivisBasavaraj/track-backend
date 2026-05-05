// File: lib/widgets/modern_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/app_theme.dart';

enum ModernButtonType { primary, secondary, outline, text, danger, success }

// For backward compatibility
enum ModernButtonStyle { primary, secondary, outline, text, danger, success }

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonType type;
  final ModernButtonStyle? style; // For backward compatibility
  final IconData? icon;
  final bool iconFirst;
  final bool isLoading;
  final bool isExpanded;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double elevation;
  final TextStyle? textStyle;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ModernButtonType.primary,
    this.style, // For backward compatibility
    this.icon,
    this.iconFirst = true,
    this.isLoading = false,
    this.isExpanded = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 12,
    this.elevation = 0,
    this.textStyle,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.easeInOutQuart,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  ModernButtonType _getEffectiveType() {
    if (widget.style != null) {
      switch (widget.style!) {
        case ModernButtonStyle.primary:
          return ModernButtonType.primary;
        case ModernButtonStyle.secondary:
          return ModernButtonType.secondary;
        case ModernButtonStyle.outline:
          return ModernButtonType.outline;
        case ModernButtonStyle.text:
          return ModernButtonType.text;
        case ModernButtonStyle.danger:
          return ModernButtonType.danger;
        case ModernButtonStyle.success:
          return ModernButtonType.success;
      }
    }
    return widget.type;
  }

  Color _getBackgroundColor() {
    if (widget.onPressed == null || widget.isLoading) {
      return AppTheme.borderColor;
    }

    switch (_getEffectiveType()) {
      case ModernButtonType.primary:
        return AppTheme.primaryColor;
      case ModernButtonType.secondary:
        return AppTheme.secondaryColor;
      case ModernButtonType.outline:
        return Colors.transparent;
      case ModernButtonType.text:
        return Colors.transparent;
      case ModernButtonType.danger:
        return AppTheme.errorColor;
      case ModernButtonType.success:
        return AppTheme.successColor;
    }
  }

  Color _getForegroundColor() {
    if (widget.onPressed == null || widget.isLoading) {
      return AppTheme.textTertiary;
    }

    switch (_getEffectiveType()) {
      case ModernButtonType.primary:
      case ModernButtonType.secondary:
      case ModernButtonType.danger:
      case ModernButtonType.success:
        return Colors.white;
      case ModernButtonType.outline:
        return AppTheme.primaryColor;
      case ModernButtonType.text:
        return AppTheme.primaryColor;
    }
  }

  BorderSide? _getBorderSide() {
    switch (_getEffectiveType()) {
      case ModernButtonType.outline:
        return BorderSide(
          color: widget.onPressed == null || widget.isLoading
              ? AppTheme.borderColor
              : AppTheme.primaryColor,
          width: 1,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 400 ? 13.0 : 14.0;
    final iconSize = screenWidth < 400 ? 16.0 : 18.0;
    
    Widget buttonChild = Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getForegroundColor()),
            ),
          )
        else ...[
          if (widget.icon != null && widget.iconFirst) ...[
            Icon(
              widget.icon,
              size: iconSize,
              color: _getForegroundColor(),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.text,
              style: widget.textStyle ??
                  TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
                    color: _getForegroundColor(),
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (widget.icon != null && !widget.iconFirst) ...[
            const SizedBox(width: 8),
            Icon(
              widget.icon,
              size: iconSize,
              color: _getForegroundColor(),
            ),
          ],
        ],
      ],
    );

    Widget button = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height ?? 48,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: _getBorderSide() != null
                  ? Border.fromBorderSide(_getBorderSide()!)
                  : null,
              boxShadow: widget.elevation > 0
                  ? [
                      BoxShadow(
                        color: _getBackgroundColor().withOpacity(0.3),
                        blurRadius: widget.elevation * 2,
                        offset: Offset(0, widget.elevation),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                onTapDown: (_) => _handleTapDown(),
                onTapUp: (_) => _handleTapUp(),
                onTapCancel: _handleTapCancel,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: _getForegroundColor().withOpacity(0.1),
                highlightColor: _getForegroundColor().withOpacity(0.05),
                child: Container(
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.isExpanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

class FloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final double elevation;
  final bool mini;

  const FloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56,
    this.elevation = 6,
    this.mini = false,
  });

  @override
  State<FloatingActionButton> createState() => _FloatingActionButtonState();
}

class _FloatingActionButtonState extends State<FloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.easeInOutQuart,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onPressed!();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.mini ? 40 : widget.size;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(size / 2),
                boxShadow: [
                  BoxShadow(
                    color: (widget.backgroundColor ?? AppTheme.primaryColor)
                        .withOpacity(0.3),
                    blurRadius: widget.elevation * 2,
                    offset: Offset(0, widget.elevation),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleTap,
                  borderRadius: BorderRadius.circular(size / 2),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      color: widget.foregroundColor ?? Colors.white,
                      size: widget.mini ? 20 : 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}