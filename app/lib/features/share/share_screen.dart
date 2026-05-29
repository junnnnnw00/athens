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

enum ShareTemplate { top5, tasteSnapshot }

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _controller = ScreenshotController();
  ShareTemplate _template = ShareTemplate.top5;
  bool _sharing = false;

  Widget _card(List<RatedCatalogItem> items) => switch (_template) {
        ShareTemplate.top5 => ShareCard.top5(items: items.take(5).toList()),
        ShareTemplate.tasteSnapshot => ShareCard.taste(items: items),
      };

  Future<void> _share(List<RatedCatalogItem> items) async {
    setState(() => _sharing = true);
    try {
      final bytes = await _controller.captureFromWidget(
        _card(items),
        pixelRatio: 3,
        targetSize: const Size(1080, 1920),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/athens_share.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Athens에서 내 음악 취향 보기');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(ratedItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('공유하기')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SegmentedButton<ShareTemplate>(
              segments: const [
                ButtonSegment(value: ShareTemplate.top5, label: Text('Top 5')),
                ButtonSegment(
                    value: ShareTemplate.tasteSnapshot,
                    label: Text('Taste Snapshot')),
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
                  child: _card(items),
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
                    : const Text('공유'),
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
  const ShareCard._({required this.items, required this.taste});

  factory ShareCard.top5({required List<RatedCatalogItem> items}) =>
      ShareCard._(items: items, taste: false);
  factory ShareCard.taste({required List<RatedCatalogItem> items}) =>
      ShareCard._(items: items, taste: true);

  final List<RatedCatalogItem> items;
  final bool taste;

  static const _p = AppPalette.dark;

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
    return AspectRatio(
      aspectRatio: 1080 / 1920,
      child: Container(
        color: _p.bg,
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(taste ? '내 취향' : '내 Top 5', style: _t(46, FontWeight.w800, _p.text)),
            const SizedBox(height: 4),
            Text('on Athens', style: _t(22, FontWeight.w600, _p.accentText)),
            const SizedBox(height: 40),
            Expanded(child: taste ? _tasteBody() : _top5Body()),
          ],
        ),
      ),
    );
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
        Text('${items.length}개 평가',
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
