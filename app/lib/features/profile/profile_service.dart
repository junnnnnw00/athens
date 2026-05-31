import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../api/supabase.dart';
import '../../data/repository/library_providers.dart';

/// The signed-in user's profile row from Supabase `profiles`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.handle,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.isPublic,
    required this.spotifyEnabled,
  });

  final String id;
  final String handle;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isPublic;
  final bool spotifyEnabled;

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        handle: m['handle'] as String? ?? '',
        displayName: m['display_name'] as String?,
        bio: m['bio'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        isPublic: m['is_public'] as bool? ?? false,
        spotifyEnabled: m['spotify_enabled'] as bool? ?? false,
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
    final row = await _client
        .from('profiles')
        .select('id, handle, display_name, bio, avatar_url, is_public, spotify_enabled')
        .eq('id', user.id)
        .maybeSingle();
    return row == null ? null : UserProfile.fromMap(row);
  }

  /// Validates a handle: 3–20 chars, lowercase letters/digits/underscore.
  static String? validateHandle(String handle) {
    final h = handle.trim();
    if (h.length < 3) return '핸들은 3자 이상이어야 해요';
    if (h.length > 20) return '핸들은 20자 이하여야 해요';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(h)) {
      return '소문자, 숫자, 밑줄(_)만 쓸 수 있어요';
    }
    return null;
  }

  /// Updates the editable profile fields. Throws [HandleTakenException] if the
  /// handle collides with another user (unique constraint 23505).
  Future<void> updateProfile({
    required String handle,
    String? displayName,
    String? bio,
    String? avatarUrl,
    required bool isPublic,
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
