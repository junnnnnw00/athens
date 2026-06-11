import 'dart:async';

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
import 'features/share/share_screen.dart';
import 'features/library/item_detail_screen.dart';
import 'features/catalog/catalog_service.dart';
import 'features/friends/friend_list_screen.dart';
import 'features/friends/friend_comparison_screen.dart';
import 'widgets/floating_nav.dart';
import 'widgets/offline_banner.dart';
import 'data/connectivity_providers.dart';
import 'data/offline_support.dart';
import 'data/repository/library_providers.dart';

import 'features/auth/landing_screen.dart';

final _rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _meNavKey = GlobalKey<NavigatorState>(debugLabel: 'me');

/// Shared item-detail route. Registered as a relative child (`item/:id`) under
/// each list-bearing parent so that a relative `push('item/<id>')` stacks the
/// detail page inside the *current* tab's navigator — the tab stays highlighted
/// and the FloatingNav remains visible above it.
GoRoute _itemRoute() => GoRoute(
      path: 'item/:id',
      builder: (c, s) {
        final catalogItem = s.extra is CatalogItem ? s.extra as CatalogItem : null;
        return ItemDetailScreen(
          itemId: s.pathParameters['id']!,
          catalogItem: catalogItem,
        );
      },
    );

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/home',
    refreshListenable: isSupabaseInitialized
        ? GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange)
        : null,
    // Safety net: any unmatched location (bad deep link, stale '/', etc.) recovers
    // to Home instead of showing go_router's red error screen.
    onException: (context, state, router) => router.go('/home'),
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
        // ONLY while genuinely offline do we keep a returning user in the app on
        // their cached local library. Online with no session = logged out (or a
        // lapsed/revoked token) → fall through to landing/auth so login & logout
        // work normally. (Without the offline gate the cached id would trap the
        // user in-app as "local-user" and block the login screen.)
        final cachedUid = ref.read(lastKnownUserIdProvider);
        final offline = ref.read(isOfflineProvider);
        if (offline && cachedUid != null && cachedUid.isNotEmpty) {
          if (loggingIn || onLanding) return '/home';
          return null;
        }
        if (loggingIn || onLanding) return null;
        return '/landing';
      }
      if (loggingIn || onLanding) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/landing', builder: (c, s) => const LandingScreen()),
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      buildAppShellRoute(),
    ],
  );
});

/// The tab shell (StatefulShellRoute) with the Home and Me branches. Exposed as
/// a top-level builder so widget tests can mount it directly without the auth
/// redirect gate (see test/widget/navigation_test.dart).
StatefulShellRoute buildAppShellRoute() => StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppShell(navigationShell: navigationShell),
      branches: [
        // ── Branch 0: Home (duel = core rating loop, search = add flow) ──
        StatefulShellBranch(
          navigatorKey: _homeNavKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (c, s) => const HomeScreen(),
              routes: [_itemRoute()],
            ),
            GoRoute(path: '/duel', builder: (c, s) => const DuelScreen()),
            GoRoute(
              path: '/duel/:focusId',
              builder: (c, s) => DuelScreen(focusId: s.pathParameters['focusId']),
            ),
            GoRoute(
              path: '/search',
              builder: (c, s) => const SearchScreen(
                  debounceDuration: Duration(milliseconds: 400)),
              routes: [_itemRoute()],
            ),
            GoRoute(path: '/share', builder: (c, s) => const ShareScreen()),
          ],
        ),
        // ── Branch 1: Me (library / stats / profile / friends) ──
        StatefulShellBranch(
          navigatorKey: _meNavKey,
          routes: [
            GoRoute(
              path: '/library',
              builder: (c, s) => const LibraryScreen(),
              routes: [
                _itemRoute(),
                // Share lives in the Me branch (library app-bar icon) so
                // pushing it keeps the Me tab active.
                GoRoute(
                    path: 'share',
                    builder: (c, s) => const ShareScreen()),
              ],
            ),
            GoRoute(path: '/stats', builder: (c, s) => const StatsScreen()),
            GoRoute(
              path: '/profile',
              builder: (c, s) => const ProfileScreen(),
              routes: [
                GoRoute(
                    path: 'edit',
                    builder: (c, s) => const ProfileEditScreen()),
              ],
            ),
            GoRoute(
              path: '/friends',
              builder: (c, s) => const FriendListScreen(),
              routes: [
                GoRoute(
                  path: 'compare/:id',
                  builder: (c, s) =>
                      FriendComparisonScreen(friendId: s.pathParameters['id']!),
                  routes: [_itemRoute()],
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Hosts the indexed-stack of tab navigators with the floating pill nav
/// overlaid at the bottom. The shell's [StatefulNavigationShell] is the single
/// source of truth for the active tab (no path-prefix heuristics).
class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static final _branchKeys = <GlobalKey<NavigatorState>>[_homeNavKey, _meNavKey];

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab again pops it back to that branch's root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  bool get _currentBranchCanPop =>
      _branchKeys[navigationShell.currentIndex].currentState?.canPop() ?? false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      // System back is allowed to exit only from the Home root with an empty
      // stack. Otherwise we either pop the current branch or fall back to Home.
      canPop: navigationShell.currentIndex == 0 && !_currentBranchCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentBranchCanPop) {
          _branchKeys[navigationShell.currentIndex].currentState?.pop();
        } else if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: _buildScaffold(context, ref),
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref) {
    // Keep the offline-support wiring (id caching + reconnect reload) alive.
    ref.watch(offlineSupportProvider);
    final offline = ref.watch(isOfflineProvider);
    final stack = Stack(
      children: [
        Positioned.fill(child: navigationShell),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingNav(
                currentIndex: navigationShell.currentIndex,
                onSelect: _goBranch,
                // Add = open search (lives in the Home branch; go() activates it).
                onAdd: () => context.go('/search'),
              ),
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      body: Column(
        children: [
          // The offline strip consumes the top safe area itself, so strip the
          // duplicate status-bar padding from the screens below it.
          if (offline) const OfflineBanner(),
          Expanded(
            child: offline
                ? MediaQuery.removePadding(
                    context: context, removeTop: true, child: stack)
                : stack,
          ),
        ],
      ),
    );
  }
}
