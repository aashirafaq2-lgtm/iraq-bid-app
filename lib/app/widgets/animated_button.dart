import 'package:flutter/material.dart';
import '../utils/app_animations.dart';

/// Enhanced animated button with multiple animation effects
class AnimatedElevatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Duration animationDuration;
  final bool enableScale;
  final bool enableRipple;

  const AnimatedElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.animationDuration = AppAnimations.fast,
    this.enableScale = true,
    this.enableRipple = true,
  });

  @override
  State<AnimatedElevatedButton> createState() => _AnimatedElevatedButtonState();
}

class _AnimatedElevatedButtonState extends State<AnimatedElevatedButton>
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
      CurvedAnimation(parent: _controller, curve: AppAnimations.smoothCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScale) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScale) {
      _controller.reverse();
    }
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.enableScale) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: widget.onPressed,
      style: widget.style,
      child: widget.child,
    );

    if (widget.enableScale) {
      button = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: button,
        ),
      );
    }

    return AppAnimations.fadeIn(child: button);
  }
}

/// Animated icon button
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size,
    this.tooltip,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smoothCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget iconButton = IconButton(
      icon: Icon(widget.icon),
      onPressed: widget.onPressed,
      color: widget.color,
      iconSize: widget.size,
      tooltip: widget.tooltip,
    );

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: iconButton,
      ),
    );
  }
}

