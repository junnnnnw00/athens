import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dev_seed.dart';
import 'router.dart';
import 'theme/app_theme.dart';

import 'api/supabase.dart';
import 'api/platform_storage.dart';
import 'data/offline_support.dart' show kLastUserIdKey;
import 'data/repository/library_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Top-level crash capture so field errors aren't silent. No crash-reporting
  // SDK is wired yet (see PRELAUNCH #3 — Sentry); until then uncaught framework
  // and async/platform errors are at least surfaced to the logs instead of
  // vanishing. PlatformDispatcher.onError is the modern catch-all (Flutter 3.3+),
  // so an explicit runZonedGuarded isn't needed.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[crash] ${details.exception}\n${details.stack}');
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('[crash] $error\n$stack');
    return true; // handled — don't also crash the isolate
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
    } catch (_) {
      // Timeout or error — proceed with startup
    }
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

  final container = ProviderContainer(
    overrides: [
      if (effectiveUserId != null && effectiveUserId.isNotEmpty)
        lastKnownUserIdProvider.overrideWith((ref) => effectiveUserId),
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

  runApp(UncontrolledProviderScope(
    container: container,
    child: const AthensApp(),
  ));
}

class AthensApp extends ConsumerWidget {
  const AthensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Athens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
