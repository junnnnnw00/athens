import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// Album/track cover. Shows the real artwork, or a quiet neutral tile with the
/// title's initials when art is missing (never a rainbow filler tile).
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.title,
    this.imageUrl,
    this.size = 56,
    this.radius = AppRadii.cover,
  });

  final String title;
  final String? imageUrl;
  final double size;
  final double radius;

  static String initialsOf(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '').trim();
    if (cleaned.isEmpty) return '?';
    return cleaned.characters.take(2).toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(p),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _fallback(p),
              )
            : _fallback(p),
      ),
    );
  }

  Widget _fallback(AppPalette p) {
    return Container(
      color: p.surface2,
      alignment: Alignment.center,
      child: Text(
        initialsOf(title),
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: size * 0.24,
          fontWeight: FontWeight.w700,
          color: p.faint,
        ),
      ),
    );
  }
}
