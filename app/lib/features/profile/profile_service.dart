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
        isPremium: m['is_premium'] as bool? ?? false,
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
        .select('id, handle, display_name, bio, avatar_url, is_public, is_premium, lastfm_username')
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
            .select('id, handle, display_name, bio, avatar_url, is_public, is_premium, lastfm_username')
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
            .select('id, handle, display_name, bio, avatar_url, is_public, is_premium, lastfm_username')
            .single();
        row = newRow;
      }
    }

    return UserProfile.fromMap(row);
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

  /// Toggles the user's premium status in the database (for development/testing).
  Future<void> togglePremium(bool premium) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await _client.from('profiles').update({'is_premium': premium}).eq('id', user.id);
  }

  /// Called after a successful Google Play purchase verification.
  ///
  /// The Edge Function [verify-play-purchase] already sets `is_premium = true`
  /// in the DB; this method is a client-side confirmation step that re-fetches
  /// the profile so Riverpod can invalidate it.
  Future<void> grantPremiumViaIap() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    // The edge function already wrote is_premium=true. Just confirm it locally.
    await _client
        .from('profiles')
        .update({'is_premium': true})
        .eq('id', user.id);
  }

  /// Redeems a promo code to unlock premium. Returns true if successful, false otherwise.
  Future<bool> redeemPromoCode(String code) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');
    
    final response = await _client.rpc(
      'redeem_promo_code',
      params: {'input_code': code},
    );
    return response as bool? ?? false;
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
