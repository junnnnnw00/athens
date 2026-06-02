import 'package:app_links/app_links.dart';
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

class AthensApp extends ConsumerStatefulWidget {
  const AthensApp({super.key});

  @override
  ConsumerState<AthensApp> createState() => _AthensAppState();
}

class _AthensAppState extends ConsumerState<AthensApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _appLinks.uriLinkStream.listen(_handleDeepLink);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
    _handleDeepLink(Uri.base);
  }

  Future<void> _handleDeepLink(Uri uri) async {
    // Deep link handler (reserved for future integrations).
  }

  @override
  Widget build(BuildContext context) {
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
