import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'platform.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const int duelReminderId = 1;
  static const int unratedTracksId = 2;
  static const int friendActivityId = 3;

  static const _channelId = 'athens_main';
  static const _channelName = 'Athens';
  static const _channelDesc = 'Athens music rating app';

  static bool get _supported =>
      !kIsWeb && (AppPlatform.isAndroid || AppPlatform.isIOS || AppPlatform.isMacOS);

  static Future<void> initialize() async {
    if (!_supported || _initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      if (AppPlatform.isAndroid) {
        return await _plugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      } else if (AppPlatform.isIOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      } else if (AppPlatform.isMacOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (_) {}
    return false;
  }

  /// Schedule a daily duel reminder. Repeats daily at [hour]:[minute].
  static Future<void> scheduleDuelReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    await cancelDuelReminder();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      duelReminderId,
      title,
      body,
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelDuelReminder() async {
    if (!_supported) return;
    try {
      await _plugin.cancel(duelReminderId);
    } catch (_) {}
  }

  static Future<void> showUnratedTracksNotification({
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    try {
      await _plugin.show(unratedTracksId, title, body, _details());
    } catch (_) {}
  }

  static Future<void> showFriendActivityNotification({
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    try {
      await _plugin.show(friendActivityId, title, body, _details());
    } catch (_) {}
  }

  static NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );
}
