import 'package:flutter/material.dart';
import '../utils/app_animations.dart';

/// Animated list view with staggered animations
class AnimatedListView extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AnimatedListView({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.duration = AppAnimations.normal,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index].animate(
          delay: delay * index,
        ).fadeIn(
          duration: duration,
          curve: AppAnimations.smoothCurve,
        ).slideX(
          duration: duration,
          curve: AppAnimations.smoothCurve,
          begin: 0.1,
          end: 0,
        );
      },
    );
  }
}

/// Animated grid view with staggered animations
class AnimatedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Duration delay;
  final Duration duration;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double childAspectRatio;

  const AnimatedGridView({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.delay = const Duration(milliseconds: 50),
    this.duration = AppAnimations.normal,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index].animate(
          delay: delay * index,
        ).fadeIn(
          duration: duration,
          curve: AppAnimations.smoothCurve,
        ).scale(
          duration: duration,
          curve: AppAnimations.smoothCurve,
          begin: Offset(0.9, 0.9),
          end: Offset(1.0, 1.0),
        );
      },
    );
  }
}

