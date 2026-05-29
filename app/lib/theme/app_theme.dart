import 'package:flutter/material.dart';

import 'tokens.dart';

/// Exposes the full [AppPalette] to widgets via `Theme.of(context)`.
@immutable
class AppPaletteExt extends ThemeExtension<AppPaletteExt> {
  const AppPaletteExt(this.palette);
  final AppPalette palette;

  @override
  AppPaletteExt copyWith({AppPalette? palette}) =>
      AppPaletteExt(palette ?? this.palette);

  @override
  AppPaletteExt lerp(ThemeExtension<AppPaletteExt>? other, double t) {
    // Palettes are discrete (dark/light); no interpolation needed.
    return this;
  }
}

extension PaletteAccess on BuildContext {
  /// The active mode's palette. Always present — registered on both themes.
  AppPalette get palette =>
      Theme.of(this).extension<AppPaletteExt>()!.palette;
}

/// Central app theme. No default Material colors survive: every slot is mapped
/// to a token from [AppPalette]. Refined-minimalist, one mint accent.
abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);
  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.bg,
      secondary: p.accent,
      onSecondary: p.bg,
      error: const Color(0xFFE5484D),
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.text,
      surfaceContainerHighest: p.surface2,
      outline: p.line,
      outlineVariant: p.line,
    );

    final textTheme = _textTheme(p);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      fontFamily: AppFonts.display,
      fontFamilyFallback: AppFonts.fallback,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      extensions: [AppPaletteExt(p)],
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.text),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.bg,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.line),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accentText),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: p.line),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.chip,
        labelStyle: textTheme.labelMedium?.copyWith(color: p.muted),
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.faint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.muted),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: p.line)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: p.accent, width: 2)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.line,
        circularTrackColor: p.line,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surface2,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
      ),
    );
  }

  static TextTheme _textTheme(AppPalette p) {
    // Heavy headings (w800, tight tracking); medium body; muted meta.
    // Apply the font family explicitly so styles captured into sub-themes
    // (e.g. AppBarTheme.titleTextStyle) always carry it.
    return _base(p).apply(
      fontFamily: AppFonts.display,
      fontFamilyFallback: AppFonts.fallback,
    );
  }

  static TextTheme _base(AppPalette p) {
    return TextTheme(
      displayLarge: TextStyle(
          fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: p.text),
      headlineMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: p.text),
      headlineSmall: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: p.text),
      titleLarge: TextStyle(
          fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: p.text),
      titleMedium: TextStyle(
          fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: p.text),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
      bodyLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w500, color: p.text),
      bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: p.text),
      bodySmall: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: p.muted),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
      labelMedium: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: p.muted),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: p.muted),
    );
  }
}
