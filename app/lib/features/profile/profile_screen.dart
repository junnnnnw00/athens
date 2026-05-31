import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repository/library_providers.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import 'profile_service.dart';
import '../../i18n.dart';
import '../stats/stats_screen.dart';

/// Base URL of the public web profile site (override at build time).
const _webBase = String.fromEnvironment('WEB_PROFILE_BASE',
    defaultValue: 'https://athens.vercel.app');

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String? _email() {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  bool _isLoggedIn() {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final email = _email();
    final isLoggedIn = _isLoggedIn();
    final count = ref.watch(ratedItemsProvider).length;
    final profileAsync = ref.watch(myProfileProvider);
    final profile = profileAsync.valueOrNull;
    final currentLang = ref.watch(localeProvider);
    final statsAsync = ref.watch(statsProvider);
    final stats = statsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('profile_me', ref: ref)),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.t('profile_edit', ref: ref),
              onPressed: () => context.go('/profile/edit'),
            ),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: context.t('profile_logout', ref: ref),
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
                  border: Border.all(color: p.line, width: 1.5),
                ),
                child: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.network(
                          profile.avatarUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            color: p.muted,
                            size: 30,
                          ),
                        ),
                      )
                    : Icon(Icons.person_rounded, color: p.muted, size: 30),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.displayName ?? email ?? context.t('profile_local_user', ref: ref),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                        profile != null
                            ? '@${profile.handle} · $count${context.t('profile_ratings_count', ref: ref)}'
                            : '$count${context.t('profile_ratings_count', ref: ref)}',
                        style: TextStyle(color: p.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (profile != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _PublicProfileCard(handle: profile.handle, isPublic: profile.isPublic),
          ],
          if (stats != null && stats.topGenres.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(context.t('profile_top_genres', ref: ref), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.topGenres.take(4).map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: p.chip,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: p.line),
                ),
                child: Text(
                  g.name,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          if (isLoggedIn)
            _Tile(
                icon: Icons.edit_outlined,
                title: context.t('profile_edit', ref: ref),
                subtitle: context.t('edit_public_desc', ref: ref),
                onTap: () => context.go('/profile/edit')),
          _Tile(
              icon: Icons.library_music_rounded,
              title: context.t('profile_library', ref: ref),
              onTap: () => context.go('/library')),
          _Tile(
              icon: Icons.insights_rounded,
              title: context.t('profile_stats', ref: ref),
              onTap: () => context.go('/stats')),
          _Tile(
              icon: Icons.link_rounded,
              title: context.t('home_spotify_connect', ref: ref),
              subtitle: context.t('profile_spotify_sub', ref: ref),
              onTap: () => context.go('/spotify-connect')),
          _Tile(
              icon: Icons.language_rounded,
              title: context.t('profile_language', ref: ref),
              subtitle: currentLang.label,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const _LanguageDialog(),
                );
              }),
        ],
      ),
    );
  }
}

class _LanguageDialog extends ConsumerWidget {
  const _LanguageDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final p = context.palette;
    return AlertDialog(
      backgroundColor: p.surface2,
      title: Text(context.t('profile_language', ref: ref), style: TextStyle(color: p.text)),
      content: RadioGroup<AppLanguage>(
        groupValue: current,
        onChanged: (val) {
          if (val != null) {
            ref.read(localeProvider.notifier).setLanguage(val);
          }
          Navigator.pop(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            return RadioListTile<AppLanguage>(
              activeColor: p.accent,
              title: Text(lang.label, style: TextStyle(color: p.text)),
              value: lang,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PublicProfileCard extends ConsumerWidget {
  const _PublicProfileCard({required this.handle, required this.isPublic});
  final String handle;
  final bool isPublic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final url = '$_webBase/u/$handle';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isPublic ? p.accentSoft : p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: isPublic ? Colors.transparent : p.line),
      ),
      child: Row(
        children: [
          Icon(isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
              size: 20, color: isPublic ? p.accentText : p.muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPublic ? context.t('profile_public', ref: ref) : context.t('profile_private', ref: ref),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isPublic ? p.accentText : p.text)),
                const SizedBox(height: 2),
                Text(isPublic ? url : context.t('profile_private_desc', ref: ref),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isPublic ? p.accentText : p.muted,
                        fontSize: 12.5)),
              ],
            ),
          ),
          if (isPublic)
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 18, color: p.accentText),
              tooltip: context.t('profile_copy_link', ref: ref),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('profile_link_copied', ref: ref))),
                  );
                }
              },
            ),
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
