import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the light & dark [ThemeData] from the centralized tokens
/// (AppColors / AppTypography / AppSpacing). This is the only place that builds
/// component themes — screens should never re-specify these.
abstract final class AppTheme {
  static ThemeData get light =>
      _build(AppColors.light, AppPalette.light, Brightness.light);

  static ThemeData get dark =>
      _build(AppColors.dark, AppPalette.dark, Brightness.dark);

  static ThemeData _build(
    ColorScheme scheme,
    AppPalette palette,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final text = AppTypography.textTheme(scheme);
    final fieldFill = isDark ? AppColors.darkRaised : AppColors.lightField;

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: AppRadii.rLg,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      canvasColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[palette],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: border(Colors.transparent),
        enabledBorder: border(palette.hairline),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.6),
        hintStyle: text.bodyMedium?.copyWith(color: palette.muted),
        labelStyle: text.bodyMedium?.copyWith(color: palette.muted),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: scheme.primary),
        prefixIconColor: palette.muted,
        suffixIconColor: palette.muted,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: text.labelLarge,
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: text.labelLarge,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: palette.hairline),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurface),
      ),

      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.rLg,
          side: BorderSide(color: palette.hairline),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkRaised : AppColors.lightField,
        side: BorderSide(color: palette.hairline),
        labelStyle: text.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rPill),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkRaisedHigh : const Color(0xFF20262F),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.brandBlueSoft,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadii.xl)),
        ),
      ),

      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: palette.muted,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
