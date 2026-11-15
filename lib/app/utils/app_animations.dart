import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';

/// App-wide animation utilities and constants
class AppAnimations {
  // Animation durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Animation curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve sharpCurve = Curves.easeInOutCubic;

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double begin = 0.0,
  }) {
    return child.animate().fadeIn(
      duration: duration,
      curve: curve,
      begin: begin,
    );
  }

  /// Slide in from bottom animation
  static Widget slideInUp({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double begin = 50.0,
  }) {
    return child.animate().slideY(
      duration: duration,
      curve: curve,
      begin: begin / 100,
      end: 0,
    ).fadeIn(duration: duration);
  }

  /// Slide in from right animation
  static Widget slideInRight({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double begin = 50.0,
  }) {
    return child.animate().slideX(
      duration: duration,
      curve: curve,
      begin: begin / 100,
      end: 0,
    ).fadeIn(duration: duration);
  }

  /// Slide in from left animation
  static Widget slideInLeft({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double begin = -50.0,
  }) {
    return child.animate().slideX(
      duration: duration,
      curve: curve,
      begin: begin / 100,
      end: 0,
    ).fadeIn(duration: duration);
  }

  /// Scale animation
  static Widget scale({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return child.animate().scale(
      duration: duration,
      curve: curve,
      begin: Offset(begin, begin),
      end: Offset(end, end),
    ).fadeIn(duration: duration);
  }

  /// Staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    Duration delay = const Duration(milliseconds: 100),
    Duration duration = normal,
    Curve curve = defaultCurve,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        return entry.value.animate(
          delay: delay * entry.key,
        ).fadeIn(
          duration: duration,
          curve: curve,
        ).slideY(
          duration: duration,
          curve: curve,
          begin: 0.2,
          end: 0,
        );
      }).toList(),
    );
  }

  /// Bounce animation
  static Widget bounce({
    required Widget child,
    Duration duration = normal,
    Curve curve = bounceCurve,
  }) {
    return child.animate().scale(
      duration: duration,
      curve: curve,
      begin: Offset(0.9, 0.9),
      end: Offset(1.0, 1.0),
    );
  }

  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return child.animate(onPlay: (controller) => controller.repeat())
        .shimmer(
      duration: const Duration(seconds: 2),
      color: highlightColor ?? Colors.white.withOpacity(0.3),
    );
  }

  /// Pulse animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return child.animate(onPlay: (controller) => controller.repeat())
        .scale(
      duration: duration,
      begin: Offset(1.0, 1.0),
      end: Offset(1.05, 1.05),
      curve: Curves.easeInOut,
    );
  }

  /// Page transition
  static Widget pageTransition({
    required Widget child,
    required BuildContext context,
    PageTransitionType type = PageTransitionType.fade,
    Duration duration = normal,
  }) {
    return PageTransitionSwitcher(
      duration: duration,
      transitionBuilder: (child, animation, secondaryAnimation) {
        switch (type) {
          case PageTransitionType.fade:
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          case PageTransitionType.slide:
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          case PageTransitionType.scale:
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.scaled,
              child: child,
            );
        }
      },
      child: child,
    );
  }
}

enum PageTransitionType {
  fade,
  slide,
  scale,
}

/// Animated container with theme transition
class AnimatedThemeContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const AnimatedThemeContainer({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AppAnimations.normal,
      curve: AppAnimations.smoothCurve,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? (isDark ? theme.colorScheme.surface : theme.colorScheme.surface),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

/// Animated button with scale effect
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Duration animationDuration;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.animationDuration = AppAnimations.fast,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated list item
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return child.animate(
      delay: delay * index,
    ).fadeIn(
      duration: AppAnimations.normal,
      curve: AppAnimations.smoothCurve,
    ).slideX(
      duration: AppAnimations.normal,
      curve: AppAnimations.smoothCurve,
      begin: 0.1,
      end: 0,
    );
  }
}

