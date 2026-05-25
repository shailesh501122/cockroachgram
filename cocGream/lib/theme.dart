import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CockroachGram design tokens — Instagram-clean light theme.
/// White backgrounds, dark text, amber as the only accent.
class CG {
  CG._();

  // ===== Colors =====
  static const bg = Color(0xFFFFFFFF);           // page background — pure white
  static const bg2 = Color(0xFFFAFAFA);          // cards / inputs — off-white
  static const bg3 = Color(0xFFF3F4F6);          // chips / surfaces — light gray
  static const line = Color(0xFFEFEFEF);         // hairline borders
  static const line2 = Color(0xFFDBDBDB);        // stronger borders
  static const accent = Color(0xFFC8720A);       // brand amber (dark)
  static const accent2 = Color(0xFFE08A0E);      // brand amber (primary on white)
  static const accentSoft = Color(0x1FE08A0E);   // ~12% alpha — chip/hover fills
  static const accentGlow = Color(0x14E08A0E);   // ~8% alpha — subtle lift
  static const text = Color(0xFF0F172A);         // near-black primary
  static const text2 = Color(0xFF475569);        // secondary
  static const text3 = Color(0xFF94A3B8);        // muted (icons-off, timestamps)
  static const danger = Color(0xFFED4956);       // Instagram-ish red (likes)
  static const success = Color(0xFF16A34A);
  static const info = Color(0xFF2563EB);

  // ===== Radii =====
  static const rSm = 8.0;
  static const rMd = 12.0;
  static const rLg = 16.0;
  static const rXl = 22.0;

  // ===== Accent helpers =====
  static const accentColor = accent2;
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );

  /// Optional soft amber shadow. Empty by default — light-theme cards rely
  /// on hairline borders, not shadows.
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
    double? spacingEm,
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
    double? spacingEm,
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
