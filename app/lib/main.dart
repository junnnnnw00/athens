import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api/spotify_pkce_service.dart';
import 'dev_seed.dart';
import 'router.dart';
import 'theme/app_theme.dart';

const _supabaseUrl =
    String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const _supabaseAnonKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
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
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final ok = await SpotifyPkceService.handleCallback(uri);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spotify 연결됨')),
      );
    }
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
