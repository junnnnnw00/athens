import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'platform.dart';

class FileStorage {
  static FileStorage? _instance;
  static Future<FileStorage> get instance async {
    if (_instance == null) {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/athens_storage.json');
      _instance = FileStorage._(file);
      await _instance!._load();
    }
    return _instance!;
  }

  final File _file;
  Map<String, String> _data = {};

  FileStorage._(this._file);

  Future<void> _load() async {
    try {
      if (await _file.exists()) {
        final content = await _file.readAsString();
        final json = jsonDecode(content);
        if (json is Map) {
          _data = json.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
    } catch (_) {
      // Corrupt/missing cache file → start empty. Non-fatal.
    }
  }

  Future<void> _save() async {
    try {
      if (!await _file.parent.exists()) {
        await _file.parent.create(recursive: true);
      }
      await _file.writeAsString(jsonEncode(_data));
    } catch (_) {
      // Best-effort local persistence; a write failure must not crash the app.
    }
  }

  Future<String?> read({required String key}) async {
    return _data[key];
  }

  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
    await _save();
  }

  Future<void> delete({required String key}) async {
    _data.remove(key);
    await _save();
  }
}

class PlatformStorage {
  static const _secure = FlutterSecureStorage(
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

  static bool get _useFileStorage => AppPlatform.isMacOS;

  static Future<String?> read({required String key}) async {
    if (_useFileStorage) {
      final storage = await FileStorage.instance;
      return storage.read(key: key);
    }
    return _secure.read(key: key);
  }

  static Future<void> write({required String key, required String value}) async {
    if (_useFileStorage) {
      final storage = await FileStorage.instance;
      await storage.write(key: key, value: value);
      return;
    }
    await _secure.write(key: key, value: value);
  }

  static Future<void> delete({required String key}) async {
    if (_useFileStorage) {
      final storage = await FileStorage.instance;
      await storage.delete(key: key);
      return;
    }
    await _secure.delete(key: key);
  }
}
