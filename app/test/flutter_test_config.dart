import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Global test harness setup (auto-loaded by `flutter test`).
///
/// `cached_network_image`'s disk cache (flutter_cache_manager) needs
/// `path_provider` + `sqflite`, neither of which has a platform implementation
/// in the unit-test host. We mock path_provider to a temp dir and route sqflite
/// to its native FFI factory so widgets that render `CachedNetworkImage` don't
/// throw `MissingPluginException`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final cacheDir = Directory.systemTemp.createTempSync('athens_test_cache');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => cacheDir.path,
  );

  await testMain();
}
