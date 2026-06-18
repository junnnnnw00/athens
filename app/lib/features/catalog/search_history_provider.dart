import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/platform_storage.dart';

const _kHistoryKey = 'search_history_v1';
const _kMaxHistory = 10;

class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    // Load async; start empty and populate once loaded.
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final raw = await PlatformStorage.read(key: _kHistoryKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List).cast<String>();
      state = list;
    } catch (_) {}
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [q, ...state.where((s) => s != q)].take(_kMaxHistory).toList();
    state = next;
    await _save();
  }

  Future<void> remove(String query) async {
    state = state.where((s) => s != query).toList();
    await _save();
  }

  Future<void> clear() async {
    state = const [];
    await _save();
  }

  Future<void> _save() async {
    try {
      await PlatformStorage.write(key: _kHistoryKey, value: jsonEncode(state));
    } catch (_) {}
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(SearchHistoryNotifier.new);
