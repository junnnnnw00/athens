import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_art.dart';
import '../catalog/catalog_service.dart';
import '../profile/profile_service.dart';
import '../../i18n.dart';

enum ShareTemplate { top5, topster, tasteSnapshot }

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _controller = ScreenshotController();
  ShareTemplate _template = ShareTemplate.top5;
  bool _sharing = false;

  Widget _card(List<RatedCatalogItem> items, AppLanguage lang) {
    final handle = ref.read(myProfileProvider).valueOrNull?.handle;
    return switch (_template) {
      ShareTemplate.top5 =>
          ShareCard.top5(items: items.take(5).toList(), lang: lang, handle: handle),
      ShareTemplate.topster =>
          ShareCard.topster(items: _topsterItems(items), lang: lang, handle: handle),
      ShareTemplate.tasteSnapshot =>
          ShareCard.taste(items: items, lang: lang, handle: handle),
    };
  }

  /// Topster = 3×3 grid of the highest-rated covers. Albums first (the
  /// classic topster is an album chart); pad with tracks/artists if needed.
  static List<RatedCatalogItem> _topsterItems(List<RatedCatalogItem> items) {
    final albums = items.where((i) => i.kind == 'album').toList();
    final rest = items.where((i) => i.kind != 'album').toList();
    return [...albums, ...rest].take(9).toList();
  }

  Future<void> _share(List<RatedCatalogItem> items) async {
    final lang = ref.read(localeProvider);
    setState(() => _sharing = true);
    try {
      final bytes = await _controller.captureFromWidget(
        _card(items, lang),
        pixelRatio: 3,
        targetSize: const Size(1080, 1920),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/athens_share.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: I18n.get('share_text', lang));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(ratedItemsProvider);
    final lang = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('share_title', ref: ref))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SegmentedButton<ShareTemplate>(
              segments: const [
                ButtonSegment(value: ShareTemplate.top5, label: Text('Top 5')),
                ButtonSegment(
                    value: ShareTemplate.topster, label: Text('Topster')),
                ButtonSegment(
                    value: ShareTemplate.tasteSnapshot, label: Text('Taste')),
              ],
              selected: {_template},
              onSelectionChanged: (s) => setState(() => _template = s.first),
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                child: SizedBox(
                  width: 360,
                  height: 640,
                  child: _card(items, lang),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.ios_share_rounded),
                label: _sharing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(context.t('share_button', ref: ref)),
                onPressed:
                    _sharing || items.isEmpty ? null : () => _share(items),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Self-contained share card — does NOT read from context (it is captured off
/// the widget tree), so all colours/fonts are explicit.
class ShareCard extends StatelessWidget {
  const ShareCard._(
      {required this.items,
      required this.template,
      required this.lang,
      this.handle});

  factory ShareCard.top5(
          {required List<RatedCatalogItem> items,
          required AppLanguage lang,
          String? handle}) =>
      ShareCard._(items: items, template: ShareTemplate.top5, lang: lang, handle: handle);
  factory ShareCard.taste(
          {required List<RatedCatalogItem> items,
          required AppLanguage lang,
          String? handle}) =>
      ShareCard._(
          items: items, template: ShareTemplate.tasteSnapshot, lang: lang, handle: handle);
  factory ShareCard.topster(
          {required List<RatedCatalogItem> items,
          required AppLanguage lang,
          String? handle}) =>
      ShareCard._(items: items, template: ShareTemplate.topster, lang: lang, handle: handle);

  final List<RatedCatalogItem> items;
  final ShareTemplate template;
  final AppLanguage lang;
  final String? handle;

  static const _p = AppPalette.dark;

  TextStyle _t(double size, FontWeight w, Color c) => TextStyle(
        fontFamily: AppFonts.display,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: w,
        color: c,
        letterSpacing: -0.3,
      );

  String get _title => switch (template) {
        ShareTemplate.top5 => I18n.get('share_card_top5', lang),
        ShareTemplate.topster => 'Topster',
        ShareTemplate.tasteSnapshot => I18n.get('share_card_taste', lang),
      };

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1080 / 1920,
      child: Container(
        color: _p.bg,
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: _t(46, FontWeight.w800, _p.text)),
            const SizedBox(height: 4),
            Text(
                handle != null && handle!.isNotEmpty
                    ? '@$handle · Athens'
                    : 'on Athens',
                style: _t(22, FontWeight.w600, _p.accentText)),
            const SizedBox(height: 40),
            Expanded(
              child: switch (template) {
                ShareTemplate.top5 => _top5Body(),
                ShareTemplate.topster => _topsterBody(),
                ShareTemplate.tasteSnapshot => _tasteBody(),
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Minimal 3×3 album-art chart. Pure grid — no scores, no text rows.
  Widget _topsterBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _gridCell(row * 3 + col),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 28),
        // Caption: ranked titles, small and muted — readable but secondary.
        for (var i = 0; i < items.length && i < 9; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${i + 1}  ${items[i].title} — ${items[i].primaryArtist ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(15, FontWeight.w500, _p.muted),
            ),
          ),
      ],
    );
  }

  Widget _gridCell(int index) {
    if (index >= items.length) {
      return Container(color: _p.surface2);
    }
    final it = items[index];
    return CoverArtStatic(title: it.title, imageUrl: it.imageUrl, size: 320);
  }

  Widget _top5Body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text('${i + 1}',
                      style: _t(28, FontWeight.w800, _p.faint)),
                ),
                CoverArtStatic(
                    title: items[i].title,
                    imageUrl: items[i].imageUrl,
                    size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(22, FontWeight.w800, _p.text)),
                      Text(items[i].primaryArtist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(17, FontWeight.w500, _p.muted)),
                    ],
                  ),
                ),
                Text(scoreFromElo(items[i].elo).toStringAsFixed(1),
                    style: _t(26, FontWeight.w800, _p.accentText)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tasteBody() {
    final counts = <String, int>{};
    for (final item in items) {
      for (final tag in item.tags) {
        counts[tag.name] = (counts[tag.name] ?? 0) + 1;
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final e in top.take(10))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: _p.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child:
                    Text(e.key, style: _t(18, FontWeight.w700, _p.accentText)),
              ),
          ],
        ),
        const Spacer(),
        Text(I18n.get('share_card_ratings_count', lang, [items.length.toString()]),
            style: _t(20, FontWeight.w600, _p.muted)),
      ],
    );
  }
}

/// Cover that does not depend on context (for off-tree capture).
class CoverArtStatic extends StatelessWidget {
  const CoverArtStatic(
      {super.key,
      required this.title,
      required this.imageUrl,
      required this.size});
  final String title;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    const p = AppPalette.dark;
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.cover),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(p))
            : _fallback(p),
      ),
    );
  }

  Widget _fallback(AppPalette p) => Container(
        color: p.surface2,
        alignment: Alignment.center,
        child: Text(CoverArt.initialsOf(title),
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontFamilyFallback: AppFonts.fallback,
              fontSize: size * 0.24,
              fontWeight: FontWeight.w700,
              color: p.faint,
            )),
      );
}
