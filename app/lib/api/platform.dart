import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized, web-safe platform checks. Every getter guards `dart:io`
/// `Platform` access behind [kIsWeb] so this is the single file that touches
/// `dart:io` for platform detection.
abstract final class AppPlatform {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Phones/tablets — used for mobile-only affordances (e.g. haptics).
  static bool get isMobile => isAndroid || isIOS;

  /// Platforms wired for the GitHub-release self-update flow (see UpdateService).
  /// Excludes Store builds since updates are managed by the App Store / Play Store.
  static bool get supportsInAppUpdate {
    const isStoreBuild = bool.fromEnvironment('STORE_BUILD');
    if (isStoreBuild) return false;
    return isAndroid || isMacOS;
  }
}
