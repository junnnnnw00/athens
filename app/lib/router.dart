import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api/supabase.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/rank/duel_screen.dart';
import 'features/library/library_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/profile_edit_screen.dart';
import 'features/catalog/search_screen.dart';
import 'features/spotify_connect/spotify_connect_screen.dart';
import 'features/share/share_screen.dart';
import 'features/library/item_detail_screen.dart';
import 'features/catalog/catalog_service.dart';
import 'features/friends/friend_list_screen.dart';
import 'features/friends/friend_comparison_screen.dart';
import 'features/premium/premium_upgrade_screen.dart';
import 'widgets/floating_nav.dart';

import 'features/auth/landing_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      if (!isSupabaseInitialized) {
        if (state.matchedLocation == '/auth' || state.matchedLocation == '/landing') {
          return '/home';
        }
        return null;
      }
      Session? session;
      try {
        session = Supabase.instance.client.auth.currentSession;
      } catch (_) {
        // Fallback for offline network failure or transient errors
      }
      final loggingIn = state.matchedLocation == '/auth';
      final onLanding = state.matchedLocation == '/landing';

      if (session == null) {
        if (loggingIn || onLanding) return null;
        return '/landing';
      }
      if (loggingIn || onLanding) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/landing', builder: (c, s) => const LandingScreen()),
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      GoRoute(path: '/premium-upgrade', builder: (c, s) => const PremiumUpgradeScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            _AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/duel', builder: (c, s) => const DuelScreen()),
          GoRoute(
              path: '/duel/:focusId',
              builder: (c, s) =>
                  DuelScreen(focusId: s.pathParameters['focusId'])),
          GoRoute(path: '/library', builder: (c, s) => const LibraryScreen()),
          GoRoute(path: '/stats', builder: (c, s) => const StatsScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
          GoRoute(
              path: '/profile/edit',
              builder: (c, s) => const ProfileEditScreen()),
          GoRoute(
              path: '/search',
              builder: (c, s) => const SearchScreen(
                  debounceDuration: Duration(milliseconds: 400))),
          GoRoute(
              path: '/spotify-connect',
              builder: (c, s) => const SpotifyConnectScreen()),
          GoRoute(
              path: '/spotify-callback',
              builder: (c, s) => const SpotifyConnectScreen()),
          GoRoute(path: '/share', builder: (c, s) => const ShareScreen()),
          GoRoute(
            path: '/item/:id',
            builder: (c, s) {
              final catalogItem = s.extra is CatalogItem ? s.extra as CatalogItem : null;
              return ItemDetailScreen(
                itemId: s.pathParameters['id']!,
                catalogItem: catalogItem,
              );
            },
          ),
          GoRoute(
            path: '/friends',
            builder: (c, s) => const FriendListScreen(),
          ),
          GoRoute(
            path: '/friends/compare/:id',
            builder: (c, s) => FriendComparisonScreen(friendId: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

/// Hosts the main screens with the floating pill nav overlaid at the bottom.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.child, required this.location});
  final Widget child;
  final String location;

  int get _navIndex {
    if (location.startsWith('/library') ||
        location.startsWith('/profile') ||
        location.startsWith('/stats') ||
        location.startsWith('/friends')) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FloatingNav(
                  currentIndex: _navIndex,
                  onSelect: (i) => context.go(i == 0 ? '/home' : '/library'),
                  onAdd: () => context.go('/search'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
