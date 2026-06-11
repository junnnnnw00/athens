import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/tokens.dart';
import '../../i18n.dart';
import '../profile/profile_service.dart';
import 'share_screen.dart' show CoverArtStatic;

/// Opens a bottom sheet previewing the review share card (Instagram-story
/// sized) with a single share action.
Future<void> showReviewShareSheet(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  String? artist,
  String? imageUrl,
  required double score,
  required String review,
}) {
  final lang = ref.read(localeProvider);
  final handle = ref.read(myProfileProvider).valueOrNull?.handle;
  final card = ReviewShareCard(
    title: title,
    artist: artist,
    imageUrl: imageUrl,
    score: score,
    review: review,
    handle: handle,
  );
  final p = AppPalette.dark;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (sheetContext) {
      var sharing = false;
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.55,
                  child: FittedBox(
                    child: SizedBox(
                      width: 360,
                      height: 640,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: p.line),
                        ),
                        child: card,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.ios_share_rounded),
                    label: sharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(I18n.get('share_button', lang)),
                    onPressed: sharing
                        ? null
                        : () async {
                            setSheetState(() => sharing = true);
                            try {
                              await _shareCard(card, lang);
                            } finally {
                              if (sheetContext.mounted) {
                                setSheetState(() => sharing = false);
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _shareCard(ReviewShareCard card, AppLanguage lang) async {
  final bytes = await ScreenshotController().captureFromWidget(
    card,
    pixelRatio: 3,
    targetSize: const Size(1080, 1920),
  );
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/athens_review_share.png');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)],
      text: I18n.get('share_text', lang));
}

/// Self-contained 1080×1920 (9:16) review card — captured off the widget tree,
/// so all colours/fonts are explicit and no context lookups happen.
class ReviewShareCard extends StatelessWidget {
  const ReviewShareCard({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.score,
    required this.review,
    this.handle,
  });

  final String title;
  final String? artist;
  final String? imageUrl;
  final double score;
  final String review;
  final String? handle;

  static const _p = AppPalette.dark;

  TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
      TextStyle(
        fontFamily: AppFonts.display,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: w,
        color: c,
        height: height,
        letterSpacing: -0.3,
      );

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1080 / 1920,
      child: Container(
        color: _p.bg,
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CoverArtStatic(title: title, imageUrl: imageUrl, size: 560),
            ),
            const SizedBox(height: 56),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _t(46, FontWeight.w800, _p.text)),
            if (artist != null && artist!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(artist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(28, FontWeight.w500, _p.muted)),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: _p.accentSoft,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(score.toStringAsFixed(1),
                      style: _t(30, FontWeight.w800, scoreColor(score))),
                ),
              ],
            ),
            const SizedBox(height: 44),
            Expanded(
              child: Text(
                '“$review”',
                maxLines: 12,
                overflow: TextOverflow.ellipsis,
                style: _t(30, FontWeight.w500, _p.text, height: 1.65),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                if (handle != null && handle!.isNotEmpty)
                  Text('@$handle', style: _t(24, FontWeight.w600, _p.muted)),
                const Spacer(),
                Text('Athens', style: _t(24, FontWeight.w800, _p.accentText)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
