import 'package:athens/theme/app_theme.dart';
import 'package:athens/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme — custom, never default Material', () {
    test('dark theme uses token colors, not Material defaults', () {
      final t = AppTheme.dark();
      expect(t.scaffoldBackgroundColor, AppPalette.dark.bg);
      expect(t.colorScheme.primary, AppPalette.dark.accent);
      expect(t.colorScheme.surface, AppPalette.dark.surface);
      expect(t.colorScheme.onSurface, AppPalette.dark.text);
      // The notorious Material defaults must NOT appear.
      expect(t.colorScheme.primary, isNot(const Color(0xFF6200EE)));
      expect(t.scaffoldBackgroundColor, isNot(Colors.blue));
      expect(t.brightness, Brightness.dark);
    });

    test('light theme uses light token colors', () {
      final t = AppTheme.light();
      expect(t.scaffoldBackgroundColor, AppPalette.light.bg);
      expect(t.colorScheme.primary, AppPalette.light.accent);
      expect(t.brightness, Brightness.light);
    });

    test('the single accent is mint, registered on the palette extension', () {
      final t = AppTheme.dark();
      final ext = t.extension<AppPaletteExt>();
      expect(ext, isNotNull);
      expect(ext!.palette.accent, const Color(0xFF74E0A4));
    });

    test('uses the bundled display font, not the platform default', () {
      expect(AppTheme.dark().textTheme.titleLarge?.fontWeight,
          FontWeight.w800);
      expect(AppFonts.display, 'Hanken Grotesk');
    });
  });
}
