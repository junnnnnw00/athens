import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// The signature element: a circular ring whose mint stroke fills proportionally
/// to `score / 10` over a hairline track, with the score centred in mint.
/// Animates its fill on mount/update.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 48});

  /// 0–10 score.
  final double score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fraction = (score / 10).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: value,
              track: p.line,
              stroke: p.accent,
            ),
            child: Center(
              child: Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontFamilyFallback: AppFonts.fallback,
                  fontSize: size * 0.29,
                  fontWeight: FontWeight.w700,
                  color: p.accentText,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.stroke,
  });

  final double fraction;
  final Color track;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final strokeWidth = size.width * 0.052;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction > 0) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.stroke != stroke;
}
