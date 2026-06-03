import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dev_seed.dart';
import 'router.dart';
import 'theme/app_theme.dart';

import 'api/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final container = ProviderContainer();
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
