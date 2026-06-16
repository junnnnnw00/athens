import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../features/catalog/catalog_service.dart' show artworkUrlProvider;

/// Known Last.fm blank-art placeholder hash; such URLs render an empty grey box.
const String _kLastfmBlankArtHash = '2a96cbd8b46e442fc41c2b86b821562f';

/// Whether [url] points at real artwork worth loading (non-empty and not the
/// Last.fm blank placeholder). Used so missing/placeholder art falls back to a
/// monogram tile instead of an empty box, including in the duel.
bool hasUsableArt(String? url) =>
    url != null && url.isNotEmpty && !url.contains(_kLastfmBlankArtHash);

/// Album/track cover. Shows the real artwork, or a quiet neutral tile with the
/// title's initials when art is missing (never a rainbow filler tile).
///
/// Pass [artist] and [kind] to enable automatic iTunes artwork fallback when
/// [imageUrl] is missing or a Last.fm placeholder.
class CoverArt extends ConsumerWidget {
  const CoverArt({
    super.key,
    required this.title,
    this.imageUrl,
    this.size = 56,
    this.radius = AppRadii.cover,
    this.artist,
    this.kind,
  });

  final String title;
  final String? imageUrl;
  final double size;
  final double radius;
  final String? artist;
  final String? kind;

  static String initialsOf(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '').trim();
    if (cleaned.isEmpty) return '?';
    return cleaned.characters.take(2).toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    String? resolvedUrl;
    if (hasUsableArt(imageUrl)) {
      resolvedUrl = imageUrl;
    } else if (artist != null && artist!.isNotEmpty) {
      resolvedUrl = ref.watch(artworkUrlProvider((
        kind: kind ?? 'track',
        artist: artist!,
        title: title,
      ))).valueOrNull;
    }

    final url = resolvedUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: hasUsableArt(url)
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, __) => _fallback(p),
                errorWidget: (_, __, ___) => _fallback(p),
              )
            : _fallback(p),
      ),
    );
  }

  Widget _fallback(AppPalette p) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualSize = (size == double.infinity || size.isInfinite || size <= 0)
            ? min(
                constraints.maxWidth.isFinite ? constraints.maxWidth : 56.0,
                constraints.maxHeight.isFinite ? constraints.maxHeight : 56.0,
              )
            : size;
        final fontSize = actualSize * 0.24;
        return Container(
          color: p.surface2,
          alignment: Alignment.center,
          child: Text(
            initialsOf(title),
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontFamilyFallback: AppFonts.fallback,
              fontSize: fontSize <= 0 ? 14.0 : fontSize,
              fontWeight: FontWeight.w700,
              color: p.faint,
            ),
          ),
        );
      },
    );
  }
}
