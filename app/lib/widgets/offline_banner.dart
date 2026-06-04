import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository/library_providers.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// Slim strip shown app-wide (by the shell) when the device is offline. Sits
/// under the status bar and communicates that the saved library still works
/// while new additions / friends are paused. Surfaces how many local changes
/// are waiting to sync.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final pending = ref.watch(pendingSyncProvider);
    final text = pending > 0
        ? '오프라인 — 변경 $pending개는 온라인 시 동기화돼요'
        : '오프라인 — 저장된 라이브러리는 그대로 이용할 수 있어요';
    return Material(
      color: p.surface2,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.line)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 15, color: p.muted),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
