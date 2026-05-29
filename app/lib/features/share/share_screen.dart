import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../domain/score.dart';
import '../catalog/catalog_service.dart';

enum ShareTemplate { top5, tasteSnapshot }

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _screenshotController = ScreenshotController();
  ShareTemplate _template = ShareTemplate.top5;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(ratedItemsProvider);
    final sorted = List<RatedCatalogItem>.from(items)
      ..sort((a, b) => b.elo.compareTo(a.elo));

    return Scaffold(
      appBar: AppBar(title: const Text('Share Your Taste')),
      body: Column(
        children: [
          SegmentedButton<ShareTemplate>(
            segments: const [
              ButtonSegment(value: ShareTemplate.top5, label: Text('Top 5')),
              ButtonSegment(
                  value: ShareTemplate.tasteSnapshot,
                  label: Text('Taste Snapshot')),
            ],
            selected: {_template},
            onSelectionChanged: (s) =>
                setState(() => _template = s.first),
          ),
          Expanded(
            child: Center(
              child: Screenshot(
                controller: _screenshotController,
                child: _template == ShareTemplate.top5
                    ? _Top5Card(items: sorted.take(5).toList())
                    : _TasteSnapshotCard(items: sorted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              icon: const Icon(Icons.share),
              label: _isSharing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Share'),
              onPressed: _isSharing ? null : _share,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final image = await _screenshotController.captureFromWidget(
        _template == ShareTemplate.top5
            ? _Top5Card(
                items: ref
                    .read(ratedItemsProvider)
                    .take(5)
                    .toList())
            : _TasteSnapshotCard(
                items: ref.read(ratedItemsProvider)),
        pixelRatio: 3,
        targetSize: const Size(1080, 1920),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/crate_share.png');
      await file.writeAsBytes(image);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My music taste on Crate',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}

class _Top5Card extends StatelessWidget {
  const _Top5Card({required this.items});
  final List<RatedCatalogItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF6B4EFF)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Top 5',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const Text('on Crate',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          ...items.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            if (e.value.primaryArtist != null)
                              Text(e.value.primaryArtist!,
                                  style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      Text(
                        scoreFromElo(e.value.elo).toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _TasteSnapshotCard extends StatelessWidget {
  const _TasteSnapshotCard({required this.items});
  final List<RatedCatalogItem> items;

  @override
  Widget build(BuildContext context) {
    final allTags = <String, int>{};
    for (final item in items) {
      for (final tag in item.tags) {
        allTags[tag.name] = (allTags[tag.name] ?? 0) + 1;
      }
    }
    final topTags = allTags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3460), Color(0xFFE94560)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Taste',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const Text('on Crate',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topTags.take(8).map((e) {
              return Chip(
                label: Text(e.key),
                backgroundColor: Colors.white24,
                labelStyle: const TextStyle(color: Colors.white),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '${items.length} items rated',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
