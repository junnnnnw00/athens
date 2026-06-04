import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/score_ring.dart';

class InitialScoreDialog extends StatefulWidget {
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
  State<InitialScoreDialog> createState() => _InitialScoreDialogState();
}

class _InitialScoreDialogState extends State<InitialScoreDialog> {
  late double _score;

  @override
  void initState() {
    super.initState();
    _score = widget.initialValue;
  }

  String get _kindLabel {
    switch (widget.itemKind) {
      case 'track':
        return '곡';
      case 'album':
        return '앨범';
      case 'artist':
        return '아티스트';
      default:
        return '항목';
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
          const Text(
            '초기 배치 점수 설정',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            '“제가 지금 생각하기에 이 $_kindLabel은 이정도예요.”',
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
                      '이 점수를 바탕으로 대략적인 첫 위치를 잡습니다. 확인 후, 다른 $_kindLabel들과 배틀(1대1 비교)을 치르며 더 정확한 최종 순위를 정하게 됩니다.',
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
            '취소',
            style: TextStyle(color: p.muted, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _score),
          child: Text(
            '확인',
            style: TextStyle(color: p.accentText, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
