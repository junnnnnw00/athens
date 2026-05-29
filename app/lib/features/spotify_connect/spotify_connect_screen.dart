import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final spotifyEnabledProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  final data = await Supabase.instance.client
      .from('profiles')
      .select('spotify_enabled')
      .eq('id', user.id)
      .maybeSingle();
  return data?['spotify_enabled'] == true;
});

class SpotifyConnectScreen extends ConsumerWidget {
  const SpotifyConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(spotifyEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Spotify Connect')),
      body: enabledAsync.when(
        data: (enabled) => enabled
            ? const _SpotifyConnectFlow()
            : const _SpotifyNotEnabled(),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 64, color: Colors.grey),
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
    );
  }
}

class _SpotifyConnectFlow extends StatelessWidget {
  const _SpotifyConnectFlow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.headphones, size: 64),
          const SizedBox(height: 16),
          Text(
            'Connect Spotify',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect your Spotify account to automatically see recently '
            'played tracks and get prompts to rate music you\'ve listened to.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.link),
            label: const Text('Connect Spotify (PKCE OAuth)'),
            onPressed: () => _startPkceFlow(context),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll be redirected to Spotify to authorize.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _startPkceFlow(BuildContext context) {
    // TODO: Launch PKCE OAuth flow via url_launcher.
    // See docs/SPOTIFY.md for redirect URI setup.
    // Requires SPOTIFY_CLIENT_ID from environment.
    // On callback, exchange code for tokens → flutter_secure_storage.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PKCE flow: configure SPOTIFY_CLIENT_ID and run on device. '
            'See MORNING-CHECKLIST.md step 2.'),
      ),
    );
  }
}
