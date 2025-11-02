// File: lib/widgets/page_transitions.dart
import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;

  SlidePageRoute({
    required this.child,
    this.direction = SlideDirection.right,
    this.duration = AppDurations.medium,
    this.curve = AppCurves.easeInOutQuart,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case SlideDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
              case SlideDirection.left:
                begin = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.right:
                begin = const Offset(1.0, 0.0);
                break;
            }

            return SlideTransition(
              position: Tween<Offset>(
                begin: begin,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: curve,
              )),
              child: child,
            );
          },
        );
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;
  final Curve curve;

  FadePageRoute({
    required this.child,
    this.duration = AppDurations.medium,
    this.curve = Curves.easeInOut,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;
  final Curve curve;

  ScalePageRoute({
    required this.child,
    this.duration = AppDurations.medium,
    this.curve = AppCurves.easeInOutQuart,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: curve,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

class RotationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;
  final Curve curve;

  RotationPageRoute({
    required this.child,
    this.duration = AppDurations.slow,
    this.curve = AppCurves.easeInOutQuart,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return RotationTransition(
              turns: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: curve,
              )),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: curve,
                )),
                child: child,
              ),
            );
          },
        );
}

class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final SharedAxisDirection direction;
  final Duration duration;

  SharedAxisPageRoute({
    required this.child,
    this.direction = SharedAxisDirection.horizontal,
    this.duration = AppDurations.medium,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset beginOffset;
            Offset endOffset;
            
            switch (direction) {
              case SharedAxisDirection.horizontal:
                beginOffset = const Offset(0.3, 0.0);
                endOffset = const Offset(-0.3, 0.0);
                break;
              case SharedAxisDirection.vertical:
                beginOffset = const Offset(0.0, 0.3);
                endOffset = const Offset(0.0, -0.3);
                break;
              case SharedAxisDirection.scaled:
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
            }

            return Stack(
              children: [
                SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: endOffset,
                  ).animate(secondaryAnimation),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1.0, end: 0.0)
                        .animate(secondaryAnimation),
                    child: Container(), // Previous page placeholder
                  ),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: beginOffset,
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AppCurves.easeInOutQuart,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final String heroTag;
  final Duration duration;

  HeroPageRoute({
    required this.child,
    required this.heroTag,
    this.duration = AppDurations.medium,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

// Helper enums
enum SlideDirection { up, down, left, right }
enum SharedAxisDirection { horizontal, vertical, scaled }

// Extension for easier navigation
extension NavigatorExtensions on NavigatorState {
  Future<T?> pushSlide<T>(
    Widget page, {
    SlideDirection direction = SlideDirection.right,
    Duration? duration,
  }) {
    return push<T>(SlidePageRoute<T>(
      child: page,
      direction: direction,
      duration: duration ?? AppDurations.medium,
    ));
  }

  Future<T?> pushFade<T>(Widget page, {Duration? duration}) {
    return push<T>(FadePageRoute<T>(
      child: page,
      duration: duration ?? AppDurations.medium,
    ));
  }

  Future<T?> pushScale<T>(Widget page, {Duration? duration}) {
    return push<T>(ScalePageRoute<T>(
      child: page,
      duration: duration ?? AppDurations.medium,
    ));
  }

  Future<T?> pushSharedAxis<T>(
    Widget page, {
    SharedAxisDirection direction = SharedAxisDirection.horizontal,
    Duration? duration,
  }) {
    return push<T>(SharedAxisPageRoute<T>(
      child: page,
      direction: direction,
      duration: duration ?? AppDurations.medium,
    ));
  }
}

// Animated list item for staggered animations
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final double slideDistance;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
    this.duration = AppDurations.medium,
    this.curve = AppCurves.easeInOutQuart,
    this.slideDistance = 30.0,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideDistance),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start animation with delay based on index
    Future.delayed(
      Duration(milliseconds: widget.index * widget.delay.inMilliseconds),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}