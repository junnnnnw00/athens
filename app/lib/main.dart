import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dev_seed.dart';
import 'router.dart';
import 'theme/app_theme.dart';

import 'api/supabase.dart';
import 'api/platform_storage.dart';
import 'data/offline_support.dart' show kLastUserIdKey;
import 'data/repository/library_providers.dart';
import 'theme/theme_providers.dart';

const _kSentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[crash] ${details.exception}\n${details.stack}');
    if (_kSentryDsn.isNotEmpty) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('[crash] $error\n$stack');
    if (_kSentryDsn.isNotEmpty) Sentry.captureException(error, stackTrace: stack);
    return true;
  };

  if (isSupabaseInitialized) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(detectSessionInUri: true),
    );
    // Wait for the first auth event (initial session recovery) to prevent route flashing
    try {
      await Supabase.instance.client.auth.onAuthStateChange.first.timeout(
        const Duration(milliseconds: 300),
      );
    } catch (_) {}
  }

  // Resolve the library owner id so a returning user can cold-start fully
  // offline (router + currentUserIdProvider use it). Priority:
  //   1. live session (valid token)        — authoritative, refresh the cache
  //   2. last cached id                     — written on a prior signed-in run
  //   3. owner of the most local ratings    — ground truth already in Drift
  String? liveUserId;
  if (isSupabaseInitialized) {
    try {
      final auth = Supabase.instance.client.auth;
      liveUserId = auth.currentUser?.id ?? auth.currentSession?.user.id;
    } catch (_) {}
  }
  String? cachedUserId;
  try {
    cachedUserId = await PlatformStorage.read(key: kLastUserIdKey);
  } catch (_) {}
  if (liveUserId != null && liveUserId.isNotEmpty) {
    // Keep the cache fresh for future offline launches.
    try {
      await PlatformStorage.write(key: kLastUserIdKey, value: liveUserId);
    } catch (_) {}
  }
  var effectiveUserId = liveUserId ?? cachedUserId;
  final savedThemeMode = await loadSavedThemeMode();
  final onboardingDone =
      await PlatformStorage.read(key: 'onboarding_done') == 'true';

  final container = ProviderContainer(
    overrides: [
      if (effectiveUserId != null && effectiveUserId.isNotEmpty)
        lastKnownUserIdProvider.overrideWith((ref) => effectiveUserId),
      themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier(savedThemeMode)),
      onboardingDoneProvider.overrideWith((ref) => onboardingDone),
    ],
  );

  // NOTE: we deliberately do NOT resurrect an owner id from the local Drift db
  // when both the live session and the cached id are absent. Login requires a
  // Supabase session, so a signed-in run always writes `last_user_id`; an absent
  // cache therefore means the user logged out (which clears it). Recovering the
  // db owner here would re-key the library to a logged-out user and trap them on
  // Home as "local-user", blocking the landing/login screen. Genuine offline
  // returning users keep their cached id and never reach this point.

  if (kDevSeed) {
    await seedDevData(container);
  }

  void runTheApp() => runApp(UncontrolledProviderScope(
        container: container,
        child: const AthensApp(),
      ));

  if (_kSentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _kSentryDsn;
        options.tracesSampleRate = 0.1;
        options.attachStacktrace = true;
      },
      appRunner: runTheApp,
    );
  } else {
    runTheApp();
  }
}

class AthensApp extends ConsumerWidget {
  const AthensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Athens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
