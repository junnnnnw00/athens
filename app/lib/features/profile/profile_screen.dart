import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repository/library_providers.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String? _email() {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final email = _email();
    final count = ref.watch(ratedItemsProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: '로그아웃',
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 110),
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: p.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.line),
                ),
                child: Icon(Icons.person_rounded, color: p.muted, size: 30),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email ?? '로컬 사용자',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('$count개 평가',
                        style: TextStyle(color: p.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _Tile(
              icon: Icons.library_music_rounded,
              title: '라이브러리',
              onTap: () => context.go('/library')),
          _Tile(
              icon: Icons.insights_rounded,
              title: '통계',
              onTap: () => context.go('/stats')),
          _Tile(
              icon: Icons.ios_share_rounded,
              title: '취향 공유',
              onTap: () => context.go('/share')),
          _Tile(
              icon: Icons.link_rounded,
              title: 'Spotify 연결',
              subtitle: '최근 들은 곡 가져오기',
              onTap: () => context.go('/spotify-connect')),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.icon,
      required this.title,
      this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Icon(icon, color: p.text, size: 22),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (subtitle != null)
                        Text(subtitle!,
                            style:
                                TextStyle(color: p.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
