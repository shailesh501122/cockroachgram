import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CockroachGram design tokens — Instagram-clean: one font (Poppins),
/// thin lines, amber as a single accent (no gradients, minimal glow).
class CG {
  CG._();

  // ===== Colors =====
  static const bg = Color(0xFF1A0F00);
  static const bg2 = Color(0xFF231500);
  static const bg3 = Color(0xFF2D1D05);
  static const line = Color(0xFF2A1A05);   // hair-line border
  static const line2 = Color(0xFF3A2710);  // slightly stronger border
  static const accent = Color(0xFFC8720A);
  static const accent2 = Color(0xFFFF9F2E);
  static const accentSoft = Color(0x29FF9F2E);    // 16% alpha — chips, hover
  static const accentGlow = Color(0x33FF9F2E);    // 20% alpha — light shadows
  static const text = Color(0xFFF5E6C8);
  static const text2 = Color(0xFFC9B99A);
  static const text3 = Color(0xFF7A6A4A);
  static const danger = Color(0xFFE03030);
  static const success = Color(0xFF2ECC71);
  static const info = Color(0xFF4EA1FF);

  // ===== Radii =====
  static const rSm = 8.0;
  static const rMd = 12.0;
  static const rLg = 16.0;
  static const rXl = 22.0;

  // ===== Accent =====
  // Single solid amber for buttons / FAB / chips. The gradient stays for the
  // brand wordmark on the splash and a few hero tiles — kept subtle.
  static const accentColor = accent2;
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );

  /// Soft amber shadow. Returns empty by default — pass `enabled: true`
  /// for the rare element that genuinely needs a hint of lift.
  static List<BoxShadow> glow({double blur = 0, double y = 0, bool enabled = false}) =>
      enabled
          ? [BoxShadow(color: accentGlow, blurRadius: blur, offset: Offset(0, y))]
          : const [];
}

/// Typography — Poppins, single family, multiple weights.
class T {
  T._();

  static const _displayWeight = FontWeight.w700;
  static const _headingWeight = FontWeight.w600;
  static const _bodyWeight = FontWeight.w400;

  /// Big number / page title. Poppins 700.
  static TextStyle display(
    double size, {
    Color color = CG.text,
    double? letterSpacing,
    double? spacingEm, // legacy: relative letter-spacing (1.0 = font size)
    double height = 1.05,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        color: color,
        fontWeight: _displayWeight,
        height: height,
        letterSpacing:
            letterSpacing ?? (spacingEm != null ? size * spacingEm : -0.5),
      );

  /// Section / card heading. Poppins 600 by default.
  static TextStyle heading(
    double size, {
    Color color = CG.text,
    FontWeight weight = _headingWeight,
    double? letterSpacing,
    double? spacingEm, // legacy
    double height = 1.25,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing:
            letterSpacing ?? (spacingEm != null ? size * spacingEm : -0.2),
      );

  /// Body text. Poppins 400 default; pass a heavier weight for emphasis.
  static TextStyle body(
    double size, {
    Color color = CG.text,
    FontWeight weight = _bodyWeight,
    double height = 1.4,
    FontStyle style = FontStyle.normal,
    double? letterSpacing,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        fontStyle: style,
        letterSpacing: letterSpacing ?? 0,
      );

  /// Uppercase label (form field labels, section captions).
  static TextStyle labelSm({Color color = CG.text3}) => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.6,
        height: 1.2,
      );
}
