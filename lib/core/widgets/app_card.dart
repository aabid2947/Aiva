import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Consistent surface card: theme color, 1px hairline border, rounded, optional tap.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      borderRadius: AppRadii.rLg,
      child: InkWell(
        borderRadius: AppRadii.rLg,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadii.rLg,
            border: Border.all(color: context.palette.hairline),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
