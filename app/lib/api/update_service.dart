import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Checks GitHub Releases for a newer version and returns a download URL.
class UpdateService {
  static const _owner = 'junnnnnw00';
  static const _repo = 'athens';
  static const _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Returns [UpdateInfo] if a newer version is available, else null.
  static Future<UpdateInfo?> checkForUpdate() async {
    // Check on Android (APK sideloading) and macOS. Skip on web/iOS/linux/windows.
    if (kIsWeb || (!Platform.isAndroid && !Platform.isMacOS)) return null;

    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);

      final resp = await http
          .get(Uri.parse(_apiUrl), headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      final latest = _parseVersion(tagName);

      if (!_isNewer(latest, current)) return null;

      // Find the correct asset (.apk for Android, .zip for macOS)
      final extension = Platform.isAndroid ? '.apk' : '.zip';
      final assets = data['assets'] as List<dynamic>? ?? [];
      final targetAsset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith(extension),
        orElse: () => null,
      );
      final downloadUrl = targetAsset != null
          ? targetAsset['browser_download_url'] as String
          : data['html_url'] as String;

      return UpdateInfo(
        currentVersion: info.version,
        latestVersion: tagName,
        downloadUrl: downloadUrl,
        releaseNotes: (data['body'] as String?) ?? '',
      );
    } catch (_) {
      return null; // silently ignore (network errors, parse errors, etc.)
    }
  }

  static List<int> _parseVersion(String v) {
    return v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  static bool _isNewer(List<int> latest, List<int> current) {
    for (var i = 0; i < 3; i++) {
      final l = i < latest.length ? latest[i] : 0;
      final c = i < current.length ? current[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
}
