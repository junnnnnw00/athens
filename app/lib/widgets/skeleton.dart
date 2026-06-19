import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// Pulsing skeleton placeholder. Prevents layout shift while async content loads.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.35 + 0.35 * _ctrl.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// A shimmer row matching the typical list-item layout (cover art + text lines).
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key, this.avatarRadius = 4});
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          SkeletonBox(width: 48, height: 48, radius: avatarRadius),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 13),
                const SizedBox(height: 6),
                SkeletonBox(width: 100, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
