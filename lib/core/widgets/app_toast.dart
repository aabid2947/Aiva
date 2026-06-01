import 'package:flutter/material.dart';

import '../app_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Semantic toast notifications (floating SnackBars) for transient feedback:
/// success / error / warning / info. One look, one place — screens should call
/// these instead of building raw SnackBars, so every message reads consistently.
///
/// Two ways to call:
///   AppToast.success(context, 'Saved.')        // from a widget
///   AppToast.errorGlobal('Could not connect.')  // from non-widget code
///                                               // (push handler, deep links)
enum _ToastKind { success, error, warning, info }

abstract final class AppToast {
  // ----- context variants (preferred) -----
  static void success(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      _show(_ToastKind.success, message,
          context: context, actionLabel: actionLabel, onAction: onAction);

  static void error(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      _show(_ToastKind.error, message,
          context: context, actionLabel: actionLabel, onAction: onAction);

  static void warning(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      _show(_ToastKind.warning, message,
          context: context, actionLabel: actionLabel, onAction: onAction);

  static void info(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      _show(_ToastKind.info, message,
          context: context, actionLabel: actionLabel, onAction: onAction);

  // ----- global variants (no BuildContext available) -----
  static void successGlobal(String message) =>
      _show(_ToastKind.success, message);
  static void errorGlobal(String message) => _show(_ToastKind.error, message);
  static void warningGlobal(String message) =>
      _show(_ToastKind.warning, message);
  static void infoGlobal(String message) => _show(_ToastKind.info, message);

  static void _show(
    _ToastKind kind,
    String message, {
    BuildContext? context,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = context != null
        ? ScaffoldMessenger.maybeOf(context)
        : scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final themeContext = context ?? scaffoldMessengerKey.currentContext;
    final theme = themeContext != null ? Theme.of(themeContext) : null;
    final isDark = theme?.brightness == Brightness.dark;
    final scheme = theme?.colorScheme;

    final accent = switch (kind) {
      _ToastKind.success => AppColors.success,
      _ToastKind.error => scheme?.error ?? AppColors.danger,
      _ToastKind.warning => AppColors.warning,
      _ToastKind.info => AppColors.info,
    };
    final icon = switch (kind) {
      _ToastKind.success => Icons.check_circle_rounded,
      _ToastKind.error => Icons.error_rounded,
      _ToastKind.warning => Icons.warning_amber_rounded,
      _ToastKind.info => Icons.info_rounded,
    };

    final base = isDark ? AppColors.darkRaisedHigh : AppColors.lightSurface;
    final onSurface =
        scheme?.onSurface ?? (isDark ? AppColors.darkOn : AppColors.lightOn);
    // A subtle semantic tint over the surface stays legible in both themes,
    // unlike a fully-saturated bar.
    final background =
        Color.alphaBlend(accent.withValues(alpha: isDark ? 0.20 : 0.12), base);
    final textStyle = (theme?.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: onSurface, fontWeight: FontWeight.w500);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: background,
      elevation: 6,
      duration: kind == _ToastKind.error
          ? const Duration(seconds: 5)
          : const Duration(milliseconds: 3200),
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.rMd,
        side: BorderSide(color: accent.withValues(alpha: 0.55)),
      ),
      content: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: textStyle)),
        ],
      ),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: accent,
              onPressed: onAction,
            )
          : null,
    );

    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
