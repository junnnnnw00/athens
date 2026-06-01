import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api/spotify_pkce_service.dart';
import 'features/spotify_connect/spotify_connect_screen.dart';
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
    final ok = await SpotifyPkceService.handleCallback(uri);
    if (ok && mounted) {
      // Refresh the connect screen's cached state so it flips to "connected".
      ref.invalidate(spotifyConnectedProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spotify 연결됨')),
      );
      context.go('/spotify-connect');
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
