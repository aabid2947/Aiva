import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A subtle, theme-aware backdrop for the auth screens: a vertical brand gradient
/// with two soft, blurred brand-colored blobs. Purely decorative.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [AppColors.darkBg, AppColors.darkSurface]
              : const [Color(0xFFFFFFFF), AppColors.lightBg],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _blob(scheme.primary.withValues(alpha: isDark ? 0.22 : 0.16), 240),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: _blob(AppColors.bronze.withValues(alpha: isDark ? 0.16 : 0.12), 280),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
