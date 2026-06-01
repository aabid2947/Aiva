import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// The "AIVA" wordmark rendered as real text in the heading font (Plus Jakarta
/// Sans) instead of a bitmap, so it stays crisp at any size and matches the theme.
/// Replaces the old `assets/images/aiva_text.png` which didn't scale.
class AivaWordmark extends StatelessWidget {
  const AivaWordmark({super.key, this.fontSize = 22, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'AIVA',
      semanticsLabel: 'AIVA',
      style: GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.brandBlue,
        letterSpacing: fontSize * 0.16,
        height: 1.0,
      ),
    );
  }
}
