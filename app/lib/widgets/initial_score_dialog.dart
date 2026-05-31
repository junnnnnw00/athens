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
  });

  final String title;
  final String itemTitle;
  final String? itemArtist;
  final String? imageUrl;
  final double initialValue;

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

  String _scoreDescription(double score) {
    if (score >= 9.0) return '인생작! 완벽해요 🌟';
    if (score >= 7.5) return '아주 마음에 들어요 👍';
    if (score >= 6.0) return '꽤 들을만하고 좋네요 🙂';
    if (score >= 4.5) return '평이하고 무난해요 😐';
    if (score >= 3.0) return '조금 아쉬운 부분들이 있네요 😕';
    if (score >= 1.5) return '별로 마음에 들지 않아요 👎';
    return '아쉬운 작품이에요 😢';
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
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
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
                    child: Image.network(
                      widget.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
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
          const SizedBox(height: 28),
          
          // Score Ring (larger size)
          ScoreRing(score: _score, size: 88),
          const SizedBox(height: 12),
          
          // Description
          Text(
            _scoreDescription(_score),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scoreColor(_score, dark: Theme.of(context).brightness == Brightness.dark),
            ),
          ),
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
        ],
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
