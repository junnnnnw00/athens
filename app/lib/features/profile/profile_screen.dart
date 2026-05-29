import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 16),
          Text(
            user?.email ?? 'Not signed in',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Connect Spotify'),
            subtitle: const Text('Import recently played tracks'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/spotify-connect'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/stats'),
          ),
        ],
      ),
    );
  }
}
