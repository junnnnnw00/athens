import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/tokens.dart';
import '../../widgets/score_ring.dart';
import '../../i18n.dart';
import '../profile/profile_service.dart';
import 'share_screen.dart' show CoverArtStatic;

/// Opens a bottom sheet previewing the review/score share card with a
/// black/white theme toggle and a single share action. Works without a
/// review — then it is just a score card.
Future<void> showReviewShareSheet(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  String? artist,
  String? imageUrl,
  required double score,
  String? review,
}) {
  final lang = ref.read(localeProvider);
  final handle = ref.read(myProfileProvider).valueOrNull?.handle;

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (sheetContext) {
      var sharing = false;
      var dark = true;
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final card = ReviewShareCard(
            title: title,
            artist: artist,
            imageUrl: imageUrl,
            score: score,
            review: review,
            handle: handle,
            dark: dark,
          );
          final size = ReviewShareCard.designSize(review);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<bool>(
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: true, label: Text('Black')),
                      ButtonSegment(value: false, label: Text('White')),
                    ],
                    selected: {dark},
                    onSelectionChanged: (s) =>
                        setSheetState(() => dark = s.first),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Full design size inside FittedBox — the box scales the
                  // 1080-wide card down to the sheet width (capped so the
                  // sheet stays compact on wide/desktop windows).
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: card,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
                                await _shareCard(card, size, lang);
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
          );
        },
      );
    },
  );
}

Future<void> _shareCard(
    ReviewShareCard card, Size size, AppLanguage lang) async {
  final bytes = await ScreenshotController().captureFromWidget(
    card,
    pixelRatio: 3,
    targetSize: size,
  );
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/athens_review_share.png');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)],
      text: I18n.get('share_text', lang));
}

/// Wide, minimal score card (cover · title/artist · score ring, review as a
/// small caption when present). Captured off the widget tree, so all
/// colours/fonts are explicit and no context lookups happen.
class ReviewShareCard extends StatelessWidget {
  const ReviewShareCard({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.score,
    this.review,
    this.handle,
    this.dark = true,
  });

  final String title;
  final String? artist;
  final String? imageUrl;
  final double score;
  final String? review;
  final String? handle;
  final bool dark;

  static bool _hasReview(String? review) =>
      review != null && review.trim().isNotEmpty;

  /// Wide banner canvas; a bit taller when a review caption is shown.
  static Size designSize(String? review) =>
      _hasReview(review) ? const Size(1080, 520) : const Size(1080, 400);

  AppPalette get _p => dark ? AppPalette.dark : AppPalette.light;

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
    final hasReview = _hasReview(review);
    final size = designSize(review);
    return AspectRatio(
      aspectRatio: size.width / size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          color: _p.bg,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CoverArtStatic(
                      title: title, imageUrl: imageUrl, size: 240, dark: dark, radius: 24),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _t(60, FontWeight.w800, _p.text)),
                        if (artist != null && artist!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(artist!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(40, FontWeight.w500, _p.muted)),
                        ],
                        const SizedBox(height: 14),
                        Text(
                            handle != null && handle!.isNotEmpty
                                ? '@$handle · Athens'
                                : 'Athens',
                            style: _t(32, FontWeight.w600, _p.faint)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  ScoreRingStatic(score: score, dark: dark, size: 190),
                ],
              ),
              if (hasReview) ...[
                const SizedBox(height: 32),
                Text(
                  '“${review!.trim()}”',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _t(44, FontWeight.w500, _p.muted, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
