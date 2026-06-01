import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../features/profile/profile_service.dart';

class PremiumLockOverlay extends ConsumerWidget {
  const PremiumLockOverlay({
    super.key,
    required this.featureName,
    required this.featureDescription,
  });

  final String featureName;
  final String featureDescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurred background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: p.bg.withValues(alpha: 0.7),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PREMIUM FEATURE',
                    style: TextStyle(
                      color: p.accentText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Icon(Icons.workspace_premium_rounded, size: 48, color: p.accent),
                const SizedBox(height: AppSpacing.md),
                Text(
                  featureName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  featureDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('Premium 활성화하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: p.bg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onPressed: () {
                    context.push('/premium-upgrade');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
