import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../api/supabase.dart';
import '../../data/repository/library_providers.dart';
import '../../i18n.dart';

/// The signed-in user's profile row from Supabase `profiles`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.handle,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.isPublic,
    required this.isPremium,
    this.lastfmUsername,
  });

  final String id;
  final String handle;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isPublic;
  final bool isPremium;
  final String? lastfmUsername;

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        handle: m['handle'] as String? ?? '',
        displayName: m['display_name'] as String?,
        bio: m['bio'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        isPublic: m['is_public'] as bool? ?? false,
        // Free app: every feature is unlocked for everyone. (No IAP / paywall.)
        isPremium: true,
        lastfmUsername: m['lastfm_username'] as String?,
      );
}

/// Thrown when a chosen handle is already taken.
class HandleTakenException implements Exception {
  const HandleTakenException();
}

class ProfileService {
  ProfileService({SupabaseClient? client}) : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  /// Loads the current user's own profile row (RLS lets you read your own).
  Future<UserProfile?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    var row = await _client
        .from('profiles')
        .select('id, handle, display_name, bio, avatar_url, is_public, lastfm_username')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      // Profile is missing (e.g. user was created before migration triggers were established).
      // Auto-create a default profile row to satisfy foreign key constraints.
      final email = user.email ?? '';
      final emailPart = email.split('@').first;
      var handle = emailPart.toLowerCase().replaceAll('.', '_');
      handle = handle.replaceAll(RegExp(r'[^a-z0-9_]'), '');
      if (handle.length < 3) handle = '${handle}123';
      if (handle.length > 20) handle = handle.substring(0, 20);

      final displayName = emailPart;
      
      try {
        final newRow = await _client
            .from('profiles')
            .upsert({
              'id': user.id,
              'handle': handle,
              'display_name': displayName,
              'is_public': true, // Make public by default so friends can find them
            })
            .select('id, handle, display_name, bio, avatar_url, is_public, lastfm_username')
            .single();
        row = newRow;
      } catch (e) {
        // Suffix with millisecond value if the first handle was already taken
        final randomHandle = '${handle}_${DateTime.now().millisecondsSinceEpoch % 1000}';
        final newRow = await _client
            .from('profiles')
            .upsert({
              'id': user.id,
              'handle': randomHandle,
              'display_name': displayName,
              'is_public': true,
            })
            .select('id, handle, display_name, bio, avatar_url, is_public, lastfm_username')
            .single();
        row = newRow;
      }
    }

    return UserProfile.fromMap(row);
  }

  /// Validates a handle: 3–20 chars, lowercase letters/digits/underscore.
  static String? validateHandle(String handle, AppLanguage lang) {
    final h = handle.trim();
    if (h.length < 3) return I18n.get('edit_handle_too_short', lang);
    if (h.length > 20) return I18n.get('edit_handle_too_long', lang);
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(h)) {
      return I18n.get('edit_handle_invalid_chars', lang);
    }
    return null;
  }

  /// Permanently deletes the signed-in user's account + all their data via the
  /// `delete-account` edge function (auth.users delete → cascade). Throws on
  /// failure so the UI can surface it.
  Future<void> deleteAccount(AppLanguage lang) async {
    final res = await _client.functions.invoke('delete-account');
    if (res.status != 200) {
      final msg = res.data is Map ? (res.data['error']?.toString() ?? '') : '';
      throw StateError(msg.isNotEmpty ? msg : I18n.get('edit_delete_account_failed', lang));
    }
  }

  /// Updates the editable profile fields. Throws [HandleTakenException] if the
  /// handle collides with another user (unique constraint 23505).
  Future<void> updateProfile({
    required String handle,
    String? displayName,
    String? bio,
    String? avatarUrl,
    required bool isPublic,
    String? lastfmUsername,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    try {
      await _client.from('profiles').update({
        'handle': handle.trim(),
        'display_name': (displayName?.trim().isEmpty ?? true)
            ? null
            : displayName!.trim(),
        'bio': (bio?.trim().isEmpty ?? true) ? null : bio!.trim(),
        'avatar_url': avatarUrl,
        'is_public': isPublic,
        'lastfm_username': (lastfmUsername?.trim().isEmpty ?? true)
            ? null
            : lastfmUsername!.trim(),
      }).eq('id', user.id);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const HandleTakenException();
      rethrow;
    }
  }

  /// Uploads a profile image file to Supabase Storage avatars bucket.
  Future<String> uploadAvatar(String filePath, String fileName) async {
    final bytes = await File(filePath).readAsBytes();
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not signed in');

    // Store in bucket using format: user_id/filename
    final path = '${user.id}/$fileName';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }
}

final profileServiceProvider =
    Provider<ProfileService>((ref) => ProfileService());

/// The current user's profile; invalidate to refresh after an edit.
final myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  if (!isSupabaseInitialized) return null;
  // Watch user ID to force re-evaluation when authentication changes
  ref.watch(currentUserIdProvider);
  return ref.watch(profileServiceProvider).getMyProfile();
});
