import 'package:flutter/material.dart';
import '../utils/app_animations.dart';

/// Animated card widget with fade and slide animations
class AnimatedCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final int? index;
  final Duration? delay;

  const AnimatedCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
    this.borderRadius,
    this.boxShadow,
    this.index,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? (isDark ? theme.colorScheme.surface : theme.colorScheme.surface),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
      ),
      child: child,
    );

    if (index != null) {
      return card.animate(
        delay: delay ?? (Duration(milliseconds: 100 * index!)),
      ).fadeIn(
        duration: AppAnimations.normal,
        curve: AppAnimations.smoothCurve,
      ).slideY(
        duration: AppAnimations.normal,
        curve: AppAnimations.smoothCurve,
        begin: 0.1,
        end: 0,
      );
    }

    return AppAnimations.fadeIn(child: card);
  }
}

