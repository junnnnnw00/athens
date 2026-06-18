import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/notification_service.dart';
import '../../api/notification_providers.dart';
import '../../data/repository/library_providers.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_providers.dart';
import 'profile_service.dart';
import '../../i18n.dart';
import '../stats/stats_screen.dart';
import '../../dev_seed.dart';

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
              onPressed: () => context.push('/profile/edit'),
            ),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: context.t('profile_logout', ref: ref),
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth
                      .signOut()
                      .timeout(const Duration(seconds: 5));
                } catch (_) {
                  // Network/timeout — clear the local session anyway so logout
                  // never hangs (e.g. offline).
                  try {
                    await Supabase.instance.client.auth
                        .signOut(scope: SignOutScope.local);
                  } catch (_) {}
                }
                if (context.mounted) context.go('/auth');
              },
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm,
            AppSpacing.xl, AppLayout.scrollBottomInset(context)),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            profile?.displayName ?? email ?? context.t('profile_local_user', ref: ref),
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
            // Premium removed — the app ships free with everything unlocked
            // (see CLAUDE.md). No membership badge, no upgrade CTA.
            if (kDebugMode || kDevSeed) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 20, color: p.accentText),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('profile_demo_title', ref: ref),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.t('profile_demo_desc', ref: ref),
                            style: TextStyle(color: p.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.bg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(60, 32),
                      ),
                      onPressed: () async {
                        final successMsg = context.t('profile_demo_success', ref: ref);
                        final failedMsg = context.t('profile_demo_failed', ref: ref);
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        try {
                          await forceReSeed(ref);
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading dialog first
                            
                            // Defer Riverpod invalidations to the next frame to prevent navigator _debugLocked error
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ref.invalidate(libraryControllerProvider);
                              ref.invalidate(statsProvider);
                              ref.invalidate(myProfileProvider);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(successMsg)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(failedMsg.replaceAll('{0}', '$e'))),
                            );
                          }
                        }
                      },
                      child: Text(context.t('profile_demo_inject_btn', ref: ref), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
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
                onTap: () => context.push('/profile/edit')),
          if (isLoggedIn)
            _Tile(
                icon: Icons.people_outline_rounded,
                title: context.t('profile_friends_title', ref: ref),
                subtitle: context.t('profile_friends_desc', ref: ref),
                onTap: () => context.push('/friends')),
          _Tile(
              icon: Icons.library_music_outlined,
              title: context.t('profile_library', ref: ref),
              onTap: () => context.go('/library')),
          _Tile(
              icon: Icons.bar_chart_rounded,
              title: context.t('profile_stats', ref: ref),
              onTap: () => context.push('/stats')),
          _Tile(
              icon: Icons.music_note_outlined,
              title: context.t('profile_lastfm_title', ref: ref),
              subtitle: profile?.lastfmUsername != null && profile!.lastfmUsername!.trim().isNotEmpty
                  ? context.t('profile_lastfm_connected', args: [profile.lastfmUsername!], ref: ref)
                  : context.t('profile_lastfm_connect_desc', ref: ref),
              onTap: () => context.push('/profile/edit')),
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
          Builder(builder: (context) {
            final themeMode = ref.watch(themeModeProvider);
            final isDark = themeMode != ThemeMode.light;
            return _Tile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: isDark ? context.t('profile_dark_mode', ref: ref) : context.t('profile_light_mode', ref: ref),
              subtitle: isDark ? context.t('profile_switch_to_light', ref: ref) : context.t('profile_switch_to_dark', ref: ref),
              onTap: () => ref.read(themeModeProvider.notifier).setMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  ),
            );
          }),
          _Tile(
              icon: Icons.notifications_outlined,
              title: context.t('profile_notif_title', ref: ref),
              subtitle: context.t('profile_notif_desc', ref: ref),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => const _NotifSettingsSheet(),
                );
              }),
          _Tile(
              icon: Icons.chat_bubble_outline_rounded,
              title: context.t('profile_feedback_title', ref: ref),
              subtitle: context.t('profile_feedback_subtitle', ref: ref),
              onTap: () async {
                final uri = Uri.parse('https://instagram.com/nerdyahh_');
                try {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {
                  // Preferred launch mode unsupported here → fall back to default.
                  await launchUrl(uri);
                }
              }),
          if (isLoggedIn)
            _Tile(
                icon: Icons.delete_outline_rounded,
                title: context.t('profile_delete_account_title', ref: ref),
                subtitle: context.t('profile_delete_account_desc', ref: ref),
                onTap: () async {
                  final deleteTitle = context.t('profile_delete_account_confirm_title', ref: ref);
                  final deleteDesc = context.t('profile_delete_account_confirm_desc', ref: ref);
                  final cancelText = context.t('lib_cancel', ref: ref);
                  final deleteText = context.t('lib_delete', ref: ref);
                  final messenger = ScaffoldMessenger.of(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(deleteTitle),
                      content: Text(deleteDesc),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(cancelText),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(deleteText, style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  try {
                    await ref.read(profileServiceProvider).deleteAccount(ref.read(localeProvider));
                    try {
                      await Supabase.instance.client.auth
                          .signOut(scope: SignOutScope.local);
                    } catch (_) {}
                    if (context.mounted) context.go('/auth');
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
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
          if (isPublic) ...[
            IconButton(
              icon: Icon(Icons.open_in_new_rounded, size: 18, color: p.accentText),
              tooltip: context.t('profile_view_tooltip', ref: ref),
              onPressed: () async {
                final uri = Uri.parse(url);
                try {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.inAppBrowserView,
                  );
                } catch (_) {
                  // Preferred launch mode unsupported here → fall back to default.
                  await launchUrl(uri);
                }
              },
            ),
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

// ── Notification settings bottom sheet ───────────────────────────────────────

class _NotifSettingsSheet extends ConsumerStatefulWidget {
  const _NotifSettingsSheet();

  @override
  ConsumerState<_NotifSettingsSheet> createState() => _NotifSettingsSheetState();
}

class _NotifSettingsSheetState extends ConsumerState<_NotifSettingsSheet> {
  bool _requesting = false;

  Future<void> _ensurePermission() async {
    setState(() => _requesting = true);
    await NotificationService.requestPermission();
    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settingsAsync = ref.watch(notifSettingsProvider);
    final lang = ref.watch(localeProvider);
    final settings = settingsAsync.valueOrNull ?? const NotifSettings();
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
            child: Text(
              context.t('profile_notif_title', ref: ref),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Divider(height: 1, color: p.line),
          // ── Friend activity ──────────────────────────────────────────
          SwitchListTile(
            value: settings.friendEnabled,
            onChanged: settingsAsync.isLoading
                ? null
                : (v) async {
                    if (v) await _ensurePermission();
                    await ref
                        .read(notifSettingsProvider.notifier)
                        .setFriendEnabled(v);
                  },
            title: Text(context.t('notif_friend_toggle', ref: ref)),
            secondary: const Icon(Icons.people_outline_rounded),
          ),
          // ── Unrated tracks ───────────────────────────────────────────
          SwitchListTile(
            value: settings.unratedEnabled,
            onChanged: settingsAsync.isLoading
                ? null
                : (v) async {
                    if (v) await _ensurePermission();
                    await ref
                        .read(notifSettingsProvider.notifier)
                        .setUnratedEnabled(v);
                  },
            title: Text(context.t('notif_unrated_toggle', ref: ref)),
            secondary: const Icon(Icons.music_note_outlined),
          ),
          // ── Duel reminder ────────────────────────────────────────────
          SwitchListTile(
            value: settings.duelReminderEnabled,
            onChanged: settingsAsync.isLoading
                ? null
                : (v) async {
                    if (v) await _ensurePermission();
                    final hour = settings.duelReminderHour;
                    final minute = settings.duelReminderMinute;
                    await ref.read(notifSettingsProvider.notifier).setDuelReminder(
                          enabled: v,
                          hour: hour,
                          minute: minute,
                          title: I18n.get('notif_duel_reminder_title', lang),
                          body: I18n.get('notif_duel_reminder_body', lang),
                        );
                  },
            title: Text(context.t('notif_duel_reminder_toggle', ref: ref)),
            secondary: const Icon(Icons.bolt_outlined),
          ),
          if (settings.duelReminderEnabled) ...[
            ListTile(
              leading: const Icon(Icons.access_time_rounded),
              title: Text(context.t('notif_duel_reminder_time', ref: ref)),
              trailing: Text(
                '${settings.duelReminderHour.toString().padLeft(2, '0')}:'
                '${settings.duelReminderMinute.toString().padLeft(2, '0')}',
                style: TextStyle(color: p.accentText, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.duelReminderHour,
                    minute: settings.duelReminderMinute,
                  ),
                );
                if (picked == null || !mounted) return;
                await ref.read(notifSettingsProvider.notifier).setDuelReminder(
                      enabled: true,
                      hour: picked.hour,
                      minute: picked.minute,
                      title: I18n.get('notif_duel_reminder_title', lang),
                      body: I18n.get('notif_duel_reminder_body', lang),
                    );
              },
            ),
          ],
          if (_requesting)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
