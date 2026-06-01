import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized type scale. Headings use Plus Jakarta Sans (geometric, confident);
/// body uses Inter (clean, legible). Sizes/weights are shared across light & dark —
/// only the color differs (it comes from the [ColorScheme]).
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme scheme) {
    final on = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    TextStyle head(double size, FontWeight weight, double spacing, double height) =>
        GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          height: height,
          color: on,
        );

    TextStyle body(double size, FontWeight weight, double height, {Color? color}) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? on,
        );

    return TextTheme(
      displaySmall: head(34, FontWeight.w700, -0.5, 1.15),
      headlineMedium: head(28, FontWeight.w700, -0.4, 1.18),
      headlineSmall: head(22, FontWeight.w600, -0.2, 1.25),
      titleLarge: head(20, FontWeight.w600, -0.1, 1.3),
      titleMedium: body(16, FontWeight.w600, 1.3),
      titleSmall: body(14, FontWeight.w600, 1.3),
      bodyLarge: body(16, FontWeight.w400, 1.45),
      bodyMedium: body(14, FontWeight.w400, 1.45),
      bodySmall: body(12.5, FontWeight.w400, 1.4, color: muted),
      labelLarge: body(14.5, FontWeight.w600, 1.1),
      labelMedium: body(12, FontWeight.w600, 1.1),
      labelSmall: body(11, FontWeight.w500, 1.1, color: muted),
    );
  }
}
