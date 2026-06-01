import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Interval-based fade + slide entrance driven by a shared [controller], offset
/// by [order] so a list of items staggers in. Reduce-motion shows items instantly.
class StaggerIn extends StatelessWidget {
  const StaggerIn({
    super.key,
    required this.controller,
    required this.order,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final start = (order * 0.06).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
          curve: AppMotion.standard),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
