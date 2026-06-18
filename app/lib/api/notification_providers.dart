import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/notification_service.dart';
import '../api/platform_storage.dart';
import '../api/supabase.dart';
import '../data/repository/library_providers.dart';
import '../features/catalog/catalog_service.dart';
import '../features/profile/profile_service.dart';
import '../i18n.dart';

// ─── Storage keys ───────────────────────────────────────────────────────────
const _kDuelEnabled = 'notif_duel_enabled';
const _kDuelHour = 'notif_duel_hour';
const _kDuelMinute = 'notif_duel_minute';
const _kUnratedEnabled = 'notif_unrated_enabled';
const _kFriendEnabled = 'notif_friend_enabled';
const _kFriendLastCheck = 'notif_friend_last_check';
const _kUnratedLastCheck = 'notif_unrated_last_check';

// ─── Settings model ──────────────────────────────────────────────────────────
class NotifSettings {
  const NotifSettings({
    this.duelReminderEnabled = false,
    this.duelReminderHour = 21,
    this.duelReminderMinute = 0,
    this.unratedEnabled = true,
    this.friendEnabled = true,
  });

  final bool duelReminderEnabled;
  final int duelReminderHour;
  final int duelReminderMinute;
  final bool unratedEnabled;
  final bool friendEnabled;

  NotifSettings copyWith({
    bool? duelReminderEnabled,
    int? duelReminderHour,
    int? duelReminderMinute,
    bool? unratedEnabled,
    bool? friendEnabled,
  }) =>
      NotifSettings(
        duelReminderEnabled: duelReminderEnabled ?? this.duelReminderEnabled,
        duelReminderHour: duelReminderHour ?? this.duelReminderHour,
        duelReminderMinute: duelReminderMinute ?? this.duelReminderMinute,
        unratedEnabled: unratedEnabled ?? this.unratedEnabled,
        friendEnabled: friendEnabled ?? this.friendEnabled,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class NotifSettingsNotifier extends AsyncNotifier<NotifSettings> {
  @override
  Future<NotifSettings> build() async {
    return NotifSettings(
      duelReminderEnabled: await PlatformStorage.read(key: _kDuelEnabled) == 'true',
      duelReminderHour: int.tryParse(await PlatformStorage.read(key: _kDuelHour) ?? '') ?? 21,
      duelReminderMinute: int.tryParse(await PlatformStorage.read(key: _kDuelMinute) ?? '') ?? 0,
      unratedEnabled: await PlatformStorage.read(key: _kUnratedEnabled) != 'false',
      friendEnabled: await PlatformStorage.read(key: _kFriendEnabled) != 'false',
    );
  }

  Future<void> setDuelReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await PlatformStorage.write(key: _kDuelEnabled, value: enabled.toString());
    await PlatformStorage.write(key: _kDuelHour, value: hour.toString());
    await PlatformStorage.write(key: _kDuelMinute, value: minute.toString());
    if (enabled) {
      await NotificationService.scheduleDuelReminder(
          hour: hour, minute: minute, title: title, body: body);
    } else {
      await NotificationService.cancelDuelReminder();
    }
    final cur = state.valueOrNull ?? const NotifSettings();
    state = AsyncData(cur.copyWith(
      duelReminderEnabled: enabled,
      duelReminderHour: hour,
      duelReminderMinute: minute,
    ));
  }

  Future<void> setUnratedEnabled(bool v) async {
    await PlatformStorage.write(key: _kUnratedEnabled, value: v.toString());
    state = AsyncData((state.valueOrNull ?? const NotifSettings()).copyWith(unratedEnabled: v));
  }

  Future<void> setFriendEnabled(bool v) async {
    await PlatformStorage.write(key: _kFriendEnabled, value: v.toString());
    state = AsyncData((state.valueOrNull ?? const NotifSettings()).copyWith(friendEnabled: v));
  }
}

final notifSettingsProvider =
    AsyncNotifierProvider<NotifSettingsNotifier, NotifSettings>(NotifSettingsNotifier.new);

// ─── Startup check ───────────────────────────────────────────────────────────

/// Called once after app starts (with a short delay) to show notifications
/// for unrated Last.fm tracks and new friend activity.
Future<void> checkStartupNotifications(ProviderContainer container) async {
  try {
    final settings = await container.read(notifSettingsProvider.future);
    final lang = container.read(localeProvider);

    // ① Unrated Last.fm tracks
    if (settings.unratedEnabled && isSupabaseInitialized) {
      await _checkUnratedTracks(container, lang);
    }

    // ② Friend activity
    if (settings.friendEnabled && isSupabaseInitialized) {
      await _checkFriendActivity(container, lang);
    }
  } catch (_) {}
}

Future<void> _checkUnratedTracks(ProviderContainer container, AppLanguage lang) async {
  try {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastCheck = await PlatformStorage.read(key: _kUnratedLastCheck);
    if (lastCheck == today) return; // already notified today

    final profile = container.read(myProfileProvider).valueOrNull;
    final lastfmUser = profile?.lastfmUsername?.trim();
    if (lastfmUser == null || lastfmUser.isEmpty) return;

    final lastfm = container.read(lastfmApiProvider);
    final recent = await lastfm.getRecentTracks(username: lastfmUser, limit: 50);
    final ratedKeys = container
        .read(ratedItemsProvider)
        .map((i) => catalogMatchKey(kind: i.kind, title: i.title, artist: i.primaryArtist))
        .toSet();

    final unratedCount = recent
        .where((t) =>
            !ratedKeys.contains(catalogMatchKey(kind: 'track', title: t.title, artist: t.artist)))
        .length;

    await PlatformStorage.write(key: _kUnratedLastCheck, value: today);

    if (unratedCount >= 5) {
      await NotificationService.showUnratedTracksNotification(
        title: I18n.get('notif_unrated_title', lang),
        body: I18n.get('notif_unrated_body', lang, ['$unratedCount']),
      );
    }
  } catch (_) {}
}

Future<void> _checkFriendActivity(ProviderContainer container, AppLanguage lang) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final lastCheckStr = await PlatformStorage.read(key: _kFriendLastCheck);
    final lastCheck = lastCheckStr != null ? DateTime.tryParse(lastCheckStr) : null;

    // Always update last check time first (so next run uses current time)
    await PlatformStorage.write(
        key: _kFriendLastCheck, value: DateTime.now().toIso8601String());

    // First run — no previous check, just record the baseline
    if (lastCheck == null) return;

    final follows = await Supabase.instance.client
        .from('follows')
        .select('following_id')
        .eq('follower_id', user.id);
    final friendIds = (follows as List).map((r) => r['following_id'] as String).toList();
    if (friendIds.isEmpty) return;

    final newRatings = await Supabase.instance.client
        .from('ratings')
        .select('user_id, updated_at')
        .inFilter('user_id', friendIds)
        .gte('updated_at', lastCheck.toIso8601String())
        .limit(50);

    if ((newRatings as List).isEmpty) return;

    await NotificationService.showFriendActivityNotification(
      title: I18n.get('notif_friend_activity_title', lang),
      body: I18n.get('notif_friend_activity_body', lang, ['${newRatings.length}']),
    );
  } catch (_) {}
}
