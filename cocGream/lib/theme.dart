import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CockroachGram design tokens — ported from the design bundle's `styles.css`.
class CG {
  CG._();

  // ===== Colors =====
  static const bg = Color(0xFF1A0F00);
  static const bg2 = Color(0xFF231500);
  static const bg3 = Color(0xFF2D1D05);
  static const line = Color(0xFF3A2710);
  static const line2 = Color(0xFF4A3318);
  static const accent = Color(0xFFC8720A);
  static const accent2 = Color(0xFFFF9F2E);
  static const accentGlow = Color(0x59FF9F2E); // rgba(255,159,46,0.35)
  static const text = Color(0xFFF5E6C8);
  static const text2 = Color(0xFFC9B99A);
  static const text3 = Color(0xFF8A7A5A);
  static const danger = Color(0xFFE03030);
  static const success = Color(0xFF2ECC71);
  static const info = Color(0xFF4EA1FF);

  // ===== Radii =====
  static const rSm = 10.0;
  static const rMd = 16.0;
  static const rLg = 20.0;
  static const rXl = 28.0;

  // ===== Gradients =====
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );

  // ===== Glows / shadows =====
  static List<BoxShadow> glow({double blur = 24, double y = 8, double spread = 0}) =>
      [BoxShadow(color: accentGlow, blurRadius: blur, offset: Offset(0, y), spreadRadius: spread)];
}

/// Typography helpers. Display = Bebas Neue, headings = Syne, body = DM Sans.
class T {
  T._();

  /// Bebas Neue — large display headings. `spacingEm` is relative to font size.
  static TextStyle display(
    double size, {
    Color color = CG.text,
    double spacingEm = 0.02,
    double height = 1.0,
  }) =>
      GoogleFonts.bebasNeue(
        fontSize: size,
        color: color,
        height: height,
        letterSpacing: size * spacingEm,
      );

  /// Syne — UI headings (weights 500–800).
  static TextStyle heading(
    double size, {
    Color color = CG.text,
    FontWeight weight = FontWeight.w800,
    double spacingEm = -0.01,
    double height = 1.2,
  }) =>
      GoogleFonts.syne(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: size * spacingEm,
      );

  /// DM Sans — body text.
  static TextStyle body(
    double size, {
    Color color = CG.text,
    FontWeight weight = FontWeight.w400,
    double height = 1.45,
    FontStyle style = FontStyle.normal,
    double? letterSpacing,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        fontStyle: style,
        letterSpacing: letterSpacing,
      );

  /// The uppercase "label-sm" treatment used for section labels.
  static TextStyle labelSm({Color color = CG.text3}) => GoogleFonts.syne(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 11 * 0.08,
      );
}
