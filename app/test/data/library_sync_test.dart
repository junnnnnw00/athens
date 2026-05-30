import 'package:athens/data/local/app_database.dart';
import 'package:athens/data/repository/library_repository.dart';
import 'package:athens/features/catalog/catalog_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fakes.dart';

CatalogItem _item(String id, String title) => CatalogItem(
      id: id,
      kind: 'album',
      title: title,
      primaryArtist: 'Artist',
      source: 'spotify',
      sourceId: id.split(':').last,
    );

void main() {
  late AppDatabase db;
  late FakeSupabaseGateway remote;
  late LibraryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeSupabaseGateway();
    repo = LibraryRepository(db: db, userId: 'auth-uuid', remote: remote);
  });
  tearDown(() => db.close());

  test('addItem pushes the item + a rating to the remote', () async {
    await repo.addItem(_item('spotify:a', 'A'));
    expect(remote.items.length, 1);
    final ratings = await remote.getRatings('auth-uuid');
    expect(ratings.length, 1);
    expect(ratings.first['item_id'], startsWith('uuid-'));
    expect(ratings.first['comparisons'], 0);
  });

  test('recordComparison pushes updated elos + comparison counts', () async {
    await repo.addItem(_item('spotify:a', 'A'));
    await repo.addItem(_item('spotify:b', 'B'));
    await repo.recordComparison(winnerId: 'spotify:a', loserId: 'spotify:b');

    final ratings = {
      for (final r in await remote.getRatings('auth-uuid')) r['item_id']: r
    };
    expect(ratings.length, 2);
    // Both have 1 comparison; winner elo > 1000 > loser elo.
    final elos = ratings.values.map((r) => r['elo'] as double).toList();
    expect(elos.any((e) => e > 1000), isTrue);
    expect(elos.any((e) => e < 1000), isTrue);
    expect(ratings.values.every((r) => r['comparisons'] == 1), isTrue);
  });

  test('local-user (signed out) does NOT sync to remote', () async {
    final localRepo =
        LibraryRepository(db: db, userId: 'local-user', remote: remote);
    await localRepo.addItem(_item('spotify:a', 'A'));
    expect(remote.items, isEmpty);
    expect(await remote.getRatings('local-user'), isEmpty);
  });

  test('remote failure never breaks the local write', () async {
    final repo2 =
        LibraryRepository(db: db, userId: 'auth-uuid', remote: _BoomGateway());
    // Should not throw despite the gateway always throwing.
    await repo2.addItem(_item('spotify:a', 'A'));
    final local = await repo2.loadLibrary();
    expect(local.length, 1); // local write succeeded
  });
}

/// Gateway whose every call throws, to prove sync is best-effort.
class _BoomGateway extends FakeSupabaseGateway {
  @override
  Future<String?> upsertItemReturningId(Map<String, dynamic> item) async =>
      throw Exception('boom');
}
