import 'package:flutter/material.dart';

/// The single source of truth for every raw color in AIVA.
///
/// Screens must NOT hardcode colors. Read brand/semantic colors from here, or —
/// preferably — from the active [ColorScheme] / [AppPalette] so light & dark adapt.
abstract final class AppColors {
  // ---------- Brand (from the logo + wordmark) ----------
  static const Color brandBlue = Color(0xFF1E9BE6); // robot logo
  static const Color brandBlueDark = Color(0xFF1478B4);
  static const Color brandBlueSoft = Color(0xFF5BBDF2);
  static const Color bronze = Color(0xFFC08A4A); // wordmark
  static const Color gold = Color(0xFFE8B563);

  // ---------- Semantic ----------
  static const Color success = Color(0xFF2BB673);
  static const Color warning = Color(0xFFE5A23B);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF3AA0FF);
  static const Color neutral = Color(0xFF8A94A6);

  // ---------- Dark neutrals ----------
  static const Color darkBg = Color(0xFF0B0E14);
  static const Color darkSurface = Color(0xFF121723);
  static const Color darkRaised = Color(0xFF1A2130);
  static const Color darkRaisedHigh = Color(0xFF222B3C);
  static const Color darkHairline = Color(0xFF273042);
  static const Color darkOn = Color(0xFFE7ECF3);
  static const Color darkOnMuted = Color(0xFF9AA6B8);

  // ---------- Light neutrals ----------
  static const Color lightBg = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightField = Color(0xFFEFF3F9);
  static const Color lightHairline = Color(0xFFE3E8F0);
  static const Color lightOn = Color(0xFF131720);
  static const Color lightOnMuted = Color(0xFF5C6677);

  // ---------- Call screen (deliberately dark surface) ----------
  static const Color callBackdrop = Color(0xFF12131A);
  static const Color callBackdropDeep = Color(0xFF07080D);
  static const Color callOn = Color(0xFFFFFFFF);
  static const Color callOnMuted = Color(0xB3FFFFFF); // ~white70
  static const Color callOnFaint = Color(0x99FFFFFF); // ~white60
  static const Color callControl = Color(0x3DFFFFFF); // ~white24
  static const Color callDangerSoft = Color(0xFFE57373); // red.shade300

  // ---------- Color schemes ----------
  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: brandBlue,
    brightness: Brightness.dark,
  ).copyWith(
    primary: brandBlue,
    onPrimary: const Color(0xFF04121C),
    secondary: bronze,
    tertiary: gold,
    error: danger,
    surface: darkSurface,
    onSurface: darkOn,
    onSurfaceVariant: darkOnMuted,
    surfaceContainerLowest: darkBg,
    surfaceContainerLow: darkSurface,
    surfaceContainer: darkRaised,
    surfaceContainerHigh: darkRaisedHigh,
    surfaceContainerHighest: const Color(0xFF273043),
    outline: darkHairline,
    outlineVariant: const Color(0xFF1E2636),
  );

  static final ColorScheme light = ColorScheme.fromSeed(
    seedColor: brandBlue,
    brightness: Brightness.light,
  ).copyWith(
    primary: brandBlue,
    onPrimary: Colors.white,
    secondary: bronze,
    tertiary: gold,
    error: danger,
    surface: lightSurface,
    onSurface: lightOn,
    onSurfaceVariant: lightOnMuted,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: lightBg,
    surfaceContainer: const Color(0xFFF1F4F9),
    surfaceContainerHigh: const Color(0xFFEAEEF5),
    surfaceContainerHighest: const Color(0xFFE3E8F0),
    outline: lightHairline,
    outlineVariant: const Color(0xFFEDF1F6),
  );
}

/// Semantic colors that don't fit the Material [ColorScheme] slots. Read via
/// `context.palette` so screens stay theme-driven (and light/dark aware).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.userBubble,
    required this.onUserBubble,
    required this.aivaBubble,
    required this.onAivaBubble,
    required this.hairline,
    required this.muted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color userBubble;
  final Color onUserBubble;
  final Color aivaBubble;
  final Color onAivaBubble;
  final Color hairline;
  final Color muted; // secondary / muted text
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  static const AppPalette dark = AppPalette(
    userBubble: AppColors.brandBlue,
    onUserBubble: Color(0xFF04121C),
    aivaBubble: AppColors.darkRaised,
    onAivaBubble: AppColors.darkOn,
    hairline: AppColors.darkHairline,
    muted: AppColors.darkOnMuted,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  static const AppPalette light = AppPalette(
    userBubble: AppColors.brandBlue,
    onUserBubble: Colors.white,
    aivaBubble: Color(0xFFEEF2F8),
    onAivaBubble: AppColors.lightOn,
    hairline: AppColors.lightHairline,
    muted: AppColors.lightOnMuted,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  @override
  AppPalette copyWith({
    Color? userBubble,
    Color? onUserBubble,
    Color? aivaBubble,
    Color? onAivaBubble,
    Color? hairline,
    Color? muted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppPalette(
      userBubble: userBubble ?? this.userBubble,
      onUserBubble: onUserBubble ?? this.onUserBubble,
      aivaBubble: aivaBubble ?? this.aivaBubble,
      onAivaBubble: onAivaBubble ?? this.onAivaBubble,
      hairline: hairline ?? this.hairline,
      muted: muted ?? this.muted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      onUserBubble: Color.lerp(onUserBubble, other.onUserBubble, t)!,
      aivaBubble: Color.lerp(aivaBubble, other.aivaBubble, t)!,
      onAivaBubble: Color.lerp(onAivaBubble, other.onAivaBubble, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// `context.palette` → the active [AppPalette]. Falls back to dark if unset.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
