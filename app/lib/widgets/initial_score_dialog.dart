import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/score_ring.dart';
import '../i18n.dart';

class InitialScoreDialog extends ConsumerStatefulWidget {
  const InitialScoreDialog({
    super.key,
    required this.title,
    required this.itemTitle,
    this.itemArtist,
    this.imageUrl,
    this.initialValue = 5.0,
    required this.itemKind,
  });

  final String title;
  final String itemTitle;
  final String? itemArtist;
  final String? imageUrl;
  final double initialValue;
  final String itemKind;

  @override
  ConsumerState<InitialScoreDialog> createState() => _InitialScoreDialogState();
}

class _InitialScoreDialogState extends ConsumerState<InitialScoreDialog> {
  late double _score;

  @override
  void initState() {
    super.initState();
    _score = widget.initialValue;
  }

  String _kindLabel(WidgetRef ref) {
    switch (widget.itemKind) {
      case 'track':
        return context.t('search_track', ref: ref);
      case 'album':
        return context.t('search_album', ref: ref);
      case 'artist':
        return context.t('search_artist', ref: ref);
      default:
        return context.t('dialog_kind_item', ref: ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      backgroundColor: p.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: p.line),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('dialog_set_initial_score', ref: ref),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            context.t('dialog_opinion_prompt', args: [_kindLabel(ref)], ref: ref),
            style: TextStyle(
              color: p.muted,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.line),
              ),
              child: Row(
                children: [
                  if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: p.surface2,
                          child: Icon(Icons.music_note_rounded, color: p.muted),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.music_note_rounded, color: p.muted),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (widget.itemArtist != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.itemArtist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Score Ring (larger size)
            ScoreRing(score: _score, size: 88),
            const SizedBox(height: 20),
            
            // Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: p.accent,
                inactiveTrackColor: p.line,
                thumbColor: p.accent,
                overlayColor: p.accent.withAlpha(51),
                valueIndicatorColor: p.surface,
                valueIndicatorTextStyle: TextStyle(color: p.text),
              ),
              child: Slider(
                value: _score,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                label: _score.toStringAsFixed(1),
                onChanged: (val) {
                  setState(() => _score = val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Placement guide notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.accentSoft.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.accentSoft.withAlpha(77)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: p.accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t('dialog_guide_notice', args: [_kindLabel(ref)], ref: ref),
                      style: TextStyle(
                        color: p.text.withAlpha(200),
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.t('dialog_cancel', ref: ref),
            style: TextStyle(color: p.muted, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _score),
          child: Text(
            context.t('dialog_confirm', ref: ref),
            style: TextStyle(color: p.accentText, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
