import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Design tokens for Athens — refined minimalism, one mint accent.
/// Source of truth: DESIGN.md. Never hardcode a color/size outside this file.

/// Maps a 0–10 score to its display colour. This is *data encoding* (like album
/// art), not chrome — a low→high spectrum (muted red → amber → mint) so a score
/// reads at a glance. The single-accent rule still governs all UI chrome.
Color scoreColor(double score, {bool dark = true}) {
  final t = (score / 10).clamp(0.0, 1.0);
  // Stops: red (0) → amber (0.5) → mint (1.0).
  const low = Color(0xFFE5604D); // muted red
  const mid = Color(0xFFE3B341); // amber
  final high = dark ? const Color(0xFF56D08D) : const Color(0xFF2E9E58); // mint
  if (t < 0.5) return _lerp(low, mid, t / 0.5);
  return _lerp(mid, high, (t - 0.5) / 0.5);
}

Color _lerp(Color a, Color b, double t) {
  return Color.fromARGB(
    255,
    lerpDouble(a.r * 255, b.r * 255, t)!.round(),
    lerpDouble(a.g * 255, b.g * 255, t)!.round(),
    lerpDouble(a.b * 255, b.b * 255, t)!.round(),
  );
}

/// Color palette for a single mode (dark or light).
@immutable
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.chip,
    required this.line,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentSoft,
    required this.accentText,
    required this.match,
    required this.matchText,
    required this.navBg,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color chip;
  final Color line;
  final Color text;
  final Color muted;
  final Color faint;

  /// The single accent — mint / spring green. No other accent exists.
  final Color accent;
  final Color accentSoft;
  final Color accentText;
  final Color match;
  final Color matchText;
  final Color navBg;

  static const dark = AppPalette(
    bg: Color(0xFF000000),
    surface: Color(0xFF141414),
    surface2: Color(0xFF1C1C1C),
    chip: Color(0xFF1E1E1E),
    line: Color(0xFF262626),
    text: Color(0xFFF2F1EE),
    muted: Color(0xFF8C8C8C),
    faint: Color(0xFF5A5A5A),
    accent: Color(0xFF74E0A4),
    accentSoft: Color(0xFF1E3A2C),
    accentText: Color(0xFF56D08D),
    match: Color(0xFF8C8A3E),
    matchText: Color(0xFF0A0A0A),
    navBg: Color(0xDB1A1A1A),
  );

  static const light = AppPalette(
    bg: Color(0xFFE9E7E2),
    surface: Color(0xFFF5F3EF),
    surface2: Color(0xFFFFFFFF),
    chip: Color(0xFFFFFFFF),
    line: Color(0xFFDAD7D0),
    text: Color(0xFF171614),
    muted: Color(0xFF6E6B64),
    faint: Color(0xFFA19D94),
    accent: Color(0xFF3DBE6E),
    accentSoft: Color(0xFFCFEFD8),
    accentText: Color(0xFF2E9E58),
    match: Color(0xFFEADF9E),
    matchText: Color(0xFF3A3722),
    navBg: Color(0xDBF0EEE9),
  );
}

/// 8px spacing scale.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Corner radii.
abstract final class AppRadii {
  static const double cover = 10;
  static const double card = 18;
  static const double pill = 20;
  static const double nav = 34;
}

/// Font families. Hanken Grotesk for Latin UI, Pretendard for Korean.
abstract final class AppFonts {
  static const String display = 'Hanken Grotesk';
  static const List<String> fallback = ['Pretendard'];
}
