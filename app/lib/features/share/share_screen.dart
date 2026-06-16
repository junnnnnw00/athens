import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
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

enum ShareTemplate { top5, topster }

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _controller = ScreenshotController();
  ShareTemplate _template = ShareTemplate.top5;
  bool _dark = true;
  bool _sharing = false;
  int _topsterCount = 16;

  Widget _card(List<RatedCatalogItem> items, AppLanguage lang) {
    final handle = ref.read(myProfileProvider).valueOrNull?.handle;
    return switch (_template) {
      ShareTemplate.top5 => ShareCard.top5(
          items: items.take(5).toList(), lang: lang, handle: handle, dark: _dark),
      ShareTemplate.topster => ShareCard.topster(
          items: _topsterItems(items, _topsterCount), lang: lang, handle: handle, dark: _dark, topsterCount: _topsterCount),
    };
  }

  /// Topster = grid of the highest-rated covers, regardless of album or track.
  /// When there are overlapping albums (sharing the same image URL), only the
  /// highest rated one is included.
  static List<RatedCatalogItem> _topsterItems(List<RatedCatalogItem> items, int count) {
    final sorted = [...items]..sort((a, b) => b.elo.compareTo(a.elo));
    final result = <RatedCatalogItem>[];
    final seenImages = <String>{};

    for (final item in sorted) {
      if (item.kind != 'album' && item.kind != 'track') {
        continue;
      }
      final img = item.imageUrl;
      if (img != null && img.isNotEmpty) {
        if (seenImages.contains(img)) {
          continue;
        }
        seenImages.add(img);
      }
      result.add(item);
    }
    return result.take(count).toList();
  }

  Future<Uint8List> _capture(List<RatedCatalogItem> items) async {
    final lang = ref.read(localeProvider);
    return _controller.captureFromWidget(
      _card(items, lang),
      pixelRatio: 3,
      targetSize: ShareCard.designSize(_template),
    );
  }

  Future<void> _share(List<RatedCatalogItem> items) async {
    final lang = ref.read(localeProvider);
    setState(() => _sharing = true);
    try {
      final bytes = await _capture(items);
      if (kIsWeb) {
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'image/png')],
          text: I18n.get('share_text', lang),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/athens_share.png');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: I18n.get('share_text', lang));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _saveToGallery(List<RatedCatalogItem> items) async {
    setState(() => _sharing = true);
    try {
      final bytes = await _capture(items);
      await Gal.putImageBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(ratedItemsProvider);
    final lang = ref.watch(localeProvider);
    final size = ShareCard.designSize(_template);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('share_title', ref: ref))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: SegmentedButton<ShareTemplate>(
              segments: const [
                ButtonSegment(value: ShareTemplate.top5, label: Text('Top 5')),
                ButtonSegment(
                    value: ShareTemplate.topster, label: Text('Topster')),
              ],
              selected: {_template},
              onSelectionChanged: (s) => setState(() => _template = s.first),
            ),
          ),
          if (_template == ShareTemplate.topster) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [9, 16, 25, 36, 49, 64].map((count) {
                  final n = sqrt(count).toInt();
                  final label = '${n}x$n ($count)';
                  final selected = _topsterCount == count;
                  return ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(label),
                    selected: selected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _topsterCount = count);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
          SegmentedButton<bool>(
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: true, label: Text('Black')),
              ButtonSegment(value: false, label: Text('White')),
            ],
            selected: {_dark},
            onSelectionChanged: (s) => setState(() => _dark = s.first),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                // Render the card at its full design size and let FittedBox
                // scale it down — rendering small and keeping 1080-based px
                // values overflows.
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: _card(items, lang),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppLayout.scrollBottomInset(context),
            ),
            child: Row(
              children: [
                if (!kIsWeb) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('저장'),
                      onPressed: _sharing || items.isEmpty ? null : () => _saveToGallery(items),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: _sharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(context.t('share_button', ref: ref)),
                    onPressed: _sharing || items.isEmpty ? null : () => _share(items),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Self-contained share card — does NOT read from context (it is captured off
/// the widget tree), so all colours/fonts are explicit. Deliberately minimal:
/// content + a hairline footer, no headers, sized to overlay on a story photo
/// rather than fill a full 9:16 canvas.
class ShareCard extends StatelessWidget {
  const ShareCard._(
      {required this.items,
      required this.template,
      required this.lang,
      this.handle,
      this.dark = true,
      this.topsterCount = 16});

  factory ShareCard.top5(
          {required List<RatedCatalogItem> items,
          required AppLanguage lang,
          String? handle,
          bool dark = true}) =>
      ShareCard._(
          items: items,
          template: ShareTemplate.top5,
          lang: lang,
          handle: handle,
          dark: dark);
  factory ShareCard.topster(
          {required List<RatedCatalogItem> items,
          required AppLanguage lang,
          String? handle,
          bool dark = true,
          int topsterCount = 16}) =>
      ShareCard._(
          items: items,
          template: ShareTemplate.topster,
          lang: lang,
          handle: handle,
          dark: dark,
          topsterCount: topsterCount);

  final List<RatedCatalogItem> items;
  final ShareTemplate template;
  final AppLanguage lang;
  final String? handle;
  final bool dark;
  final int topsterCount;

  static const int topsterCountDefault = 16;

  /// Export canvas per template (logical px; captured at 3× pixel ratio).
  static Size designSize(ShareTemplate t) => switch (t) {
        ShareTemplate.top5 => const Size(1080, 760),
        ShareTemplate.topster => const Size(1080, 1180),
      };

  AppPalette get _p => dark ? AppPalette.dark : AppPalette.light;

  TextStyle _t(double size, FontWeight w, Color c) => TextStyle(
        fontFamily: AppFonts.display,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: w,
        color: c,
        letterSpacing: -0.3,
      );

  @override
  Widget build(BuildContext context) {
    final size = designSize(template);
    return AspectRatio(
      aspectRatio: size.width / size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          color: _p.bg,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: switch (template) {
                  ShareTemplate.top5 => _top5Body(),
                  ShareTemplate.topster => _topsterBody(),
                },
              ),
              const SizedBox(height: 16),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() => Row(
        children: [
          if (handle != null && handle!.isNotEmpty)
            Text('@$handle', style: _t(22, FontWeight.w600, _p.muted)),
          const Spacer(),
          Text('Athens', style: _t(22, FontWeight.w800, _p.accentText)),
        ],
      );

  Widget _top5Body() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text('${i + 1}',
                      style: _t(38, FontWeight.w800, _p.faint)),
                ),
                CoverArtStatic(
                    title: items[i].title,
                    imageUrl: items[i].imageUrl,
                    size: 110,
                    dark: dark),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(36, FontWeight.w800, _p.text)),
                      const SizedBox(height: 4),
                      Text(items[i].primaryArtist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(26, FontWeight.w500, _p.muted)),
                    ],
                  ),
                ),
                Text(scoreFromElo(items[i].elo).toStringAsFixed(1),
                    style: _t(38, FontWeight.w800,
                        scoreColor(scoreFromElo(items[i].elo), dark: dark))),
              ],
            ),
          ),
      ],
    );
  }

  /// Pure N×N album-art chart — covers only, no text, flush tile layout.
  Widget _topsterBody() {
    final n = sqrt(topsterCount).toInt();
    final cellSize = (1080 - 64) / n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < n; row++)
          Row(
            children: [
              for (var col = 0; col < n; col++)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _gridCell(row * n + col, cellSize),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _gridCell(int index, double cellSize) {
    if (index >= items.length) {
      return Container(color: _p.surface2);
    }
    final it = items[index];
    return CoverArtStatic(
        title: it.title, imageUrl: it.imageUrl, size: cellSize, dark: dark, radius: 0);
  }


}

/// Cover that does not depend on context (for off-tree capture).
class CoverArtStatic extends StatelessWidget {
  const CoverArtStatic(
      {super.key,
      required this.title,
      required this.imageUrl,
      required this.size,
      this.dark = true,
      this.radius});
  final String title;
  final String? imageUrl;
  final double size;
  final bool dark;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final p = dark ? AppPalette.dark : AppPalette.light;
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? AppRadii.cover),
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
