import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../api/supabase.dart';
import '../../api/spotify_pkce_service.dart';

final spotifyEnabledProvider = FutureProvider<bool>((ref) async {
  if (!isSupabaseInitialized) return false;
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  final data = await Supabase.instance.client
      .from('profiles')
      .select('spotify_enabled')
      .eq('id', user.id)
      .maybeSingle();
  return data?['spotify_enabled'] == true;
});

final spotifyConnectedProvider = FutureProvider<bool>((ref) async {
  return SpotifyPkceService.isConnected();
});

class SpotifyConnectScreen extends ConsumerWidget {
  const SpotifyConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(spotifyEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Spotify Connect')),
      body: enabledAsync.when(
        data: (enabled) =>
            enabled ? const _SpotifyConnectFlow() : const _SpotifyNotEnabled(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SpotifyNotEnabled extends StatelessWidget {
  const _SpotifyNotEnabled();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off,
                  size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Spotify connect is invite-only',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Due to Spotify\'s developer mode restrictions, only a small '
                'number of users can connect their Spotify account. '
                'You can still use all other features of Athens — search, '
                'rate, stats, and sharing — without Spotify.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotifyConnectFlow extends ConsumerStatefulWidget {
  const _SpotifyConnectFlow();

  @override
  ConsumerState<_SpotifyConnectFlow> createState() =>
      _SpotifyConnectFlowState();
}

class _SpotifyConnectFlowState extends ConsumerState<_SpotifyConnectFlow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final connectedAsync = ref.watch(spotifyConnectedProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: connectedAsync.when(
            data: (connected) => connected ? _connected() : _disconnected(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _connected() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle,
            size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('Spotify Connected',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text(
          'Recently played tracks will appear in your home feed.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.link_off),
          label: const Text('Disconnect'),
          onPressed: _loading ? null : _disconnect,
        ),
      ],
    );
  }

  Widget _disconnected() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.headphones, size: 64),
        const SizedBox(height: 16),
        Text('Connect Spotify', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text(
          'Connect your Spotify account to automatically see recently '
          'played tracks and get prompts to rate music you\'ve listened to.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link),
          label: const Text('Connect Spotify'),
          onPressed: _loading ? null : _connect,
        ),
      ],
    );
  }

  Future<void> _connect() async {
    // Desktop builds lack the keychain entitlement (ad-hoc signed), so the PKCE
    // token store fails there. Web + mobile use PKCE in-page / via deep link.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spotify 연결은 모바일 및 macOS 앱에서만 지원돼요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await SpotifyPkceService.launchAuth();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch Spotify: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _loading = true);
    try {
      await SpotifyPkceService.disconnect();
      ref.invalidate(spotifyConnectedProvider);
      ref.invalidate(spotifyEnabledProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
