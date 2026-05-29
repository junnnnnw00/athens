import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _clientId = String.fromEnvironment('SPOTIFY_CLIENT_ID', defaultValue: '');
const _redirectUri = 'athens://spotify-callback';
const _scopes = 'user-read-recently-played';

const _storage = FlutterSecureStorage();
const _kVerifier = 'spotify_code_verifier';
const _kAccessToken = 'spotify_access_token';
const _kRefreshToken = 'spotify_refresh_token';
const _kExpiry = 'spotify_token_expiry';

class SpotifyPkceService {
  static String _verifier() {
    final rng = Random.secure();
    final bytes = List<int>.generate(64, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _challenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  static Future<void> launchAuth() async {
    final v = _verifier();
    await _storage.write(key: _kVerifier, value: v);
    final uri = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': _challenge(v),
      'scope': _scopes,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Returns true if callback was handled successfully.
  static Future<bool> handleCallback(Uri uri) async {
    if (uri.scheme != 'athens' || uri.host != 'spotify-callback') return false;
    final code = uri.queryParameters['code'];
    if (code == null) return false;

    final verifier = await _storage.read(key: _kVerifier);
    if (verifier == null) return false;

    final res = await http.post(
      Uri.https('accounts.spotify.com', '/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'client_id': _clientId,
        'code_verifier': verifier,
      },
    );
    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final expiry = DateTime.now()
        .add(Duration(seconds: data['expires_in'] as int))
        .toIso8601String();

    await Future.wait([
      _storage.write(key: _kAccessToken, value: data['access_token'] as String),
      _storage.write(
          key: _kRefreshToken, value: (data['refresh_token'] as String?) ?? ''),
      _storage.write(key: _kExpiry, value: expiry),
      _storage.delete(key: _kVerifier),
    ]);

    // Fetch Spotify user ID and mark profile enabled.
    await _syncProfile(data['access_token'] as String);
    return true;
  }

  static Future<void> _syncProfile(String accessToken) async {
    final res = await http.get(
      Uri.https('api.spotify.com', '/v1/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode != 200) return;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final spotifyId = data['id'] as String?;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || spotifyId == null) return;
    await Supabase.instance.client.from('profiles').update({
      'spotify_enabled': true,
      'spotify_user_id': spotifyId,
    }).eq('id', user.id);
  }

  static Future<String?> getValidAccessToken() async {
    final token = await _storage.read(key: _kAccessToken);
    if (token == null) return null;
    final expiryStr = await _storage.read(key: _kExpiry);
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isBefore(expiry.subtract(const Duration(minutes: 1)))) {
        return token;
      }
    }
    return _refresh();
  }

  static Future<String?> _refresh() async {
    final refreshToken = await _storage.read(key: _kRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final res = await http.post(
      Uri.https('accounts.spotify.com', '/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': _clientId,
      },
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final expiry = DateTime.now()
        .add(Duration(seconds: data['expires_in'] as int))
        .toIso8601String();
    await Future.wait([
      _storage.write(key: _kAccessToken, value: data['access_token'] as String),
      _storage.write(key: _kExpiry, value: expiry),
      if (data['refresh_token'] != null)
        _storage.write(
            key: _kRefreshToken, value: data['refresh_token'] as String),
    ]);
    return data['access_token'] as String;
  }

  static Future<bool> isConnected() async =>
      (await _storage.read(key: _kAccessToken)) != null;

  static Future<void> disconnect() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('profiles').update({
        'spotify_enabled': false,
        'spotify_user_id': null,
      }).eq('id', user.id);
    }
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kExpiry),
    ]);
  }
}
