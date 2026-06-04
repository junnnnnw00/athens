import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repository/library_providers.dart';
import '../catalog/catalog_service.dart';

String _infoKey(String kind, String artist, String title) =>
    '$kind|${artist.toLowerCase().trim()}|${title.toLowerCase().trim()}';

/// Rich item detail info with a persistent local cache. Tries the network first
/// and saves a successful (non-empty) result; when offline (or the fetch fails),
/// returns the last-cached info so the detail screen stays fully populated
/// offline for items already viewed. Rethrows only when nothing is cached, so
/// the existing "no info" UI is preserved.
final cachedItemInfoProvider = FutureProvider.family<ItemInfo,
    ({String kind, String artist, String title})>((ref, args) async {
  final db = ref.watch(appDatabaseProvider);
  final svc = ref.watch(catalogServiceProvider);
  final key = _infoKey(args.kind, args.artist, args.title);

  Future<ItemInfo?> readCache() async {
    final row = await db.getItemInfo(key);
    if (row == null) return null;
    try {
      return ItemInfo.fromJson(jsonDecode(row.json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  try {
    final info = await svc.fetchItemInfo(
        kind: args.kind, artist: args.artist, title: args.title);
    if (!info.isEmpty) {
      await db.upsertItemInfo(LocalItemInfosCompanion(
        key: Value(key),
        json: Value(jsonEncode(info.toJson())),
        updatedAt: Value(DateTime.now()),
      ));
      return info;
    }
    // Network reachable but returned nothing useful — prefer a richer cache.
    return (await readCache()) ?? info;
  } catch (_) {
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  }
});
