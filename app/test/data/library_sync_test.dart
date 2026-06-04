import 'package:athens/data/local/app_database.dart';
import 'package:athens/data/repository/library_repository.dart';
import 'package:athens/features/catalog/catalog_service.dart';
import 'package:drift/drift.dart' show Value;
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
    await pumpEventQueue(); // remote sync is fire-and-forget; let it flush
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
    await pumpEventQueue(); // fire-and-forget remote sync flushes here

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

  test('pullRemote hydrates a fresh device from the remote library', () async {
    // Device A rates two items and duels them — all pushed to the shared remote.
    await repo.addItem(_item('spotify:a', 'A'));
    await repo.addItem(_item('spotify:b', 'B'));
    await repo.recordComparison(winnerId: 'spotify:a', loserId: 'spotify:b');
    await pumpEventQueue(); // ensure device A's detached pushes reach the remote

    // Device B: a brand-new local DB, same user + same remote, empty to start.
    final dbB = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(dbB.close);
    final repoB = LibraryRepository(db: dbB, userId: 'auth-uuid', remote: remote);
    expect(await repoB.loadLibrary(), isEmpty);

    await repoB.pullRemote();
    final lib = await repoB.loadLibrary();

    expect(lib.length, 2);
    expect(lib.map((i) => i.id), containsAll(['spotify:a', 'spotify:b']));
    // Winner outranks loser and the comparison count survived the round-trip.
    expect(lib.first.id, 'spotify:a');
    expect(lib.every((i) => i.comparisons == 1), isTrue);
  });

  test('pullRemote does not clobber a newer local rating (last-write-wins)',
      () async {
    await repo.addItem(_item('spotify:a', 'A')); // remote rating at ~now
    await pumpEventQueue(); // flush the detached push before device B pulls

    final dbB = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(dbB.close);
    final repoB = LibraryRepository(db: dbB, userId: 'auth-uuid', remote: remote);
    await repoB.pullRemote();

    // A newer local-only edit (e.g. an offline duel) that the remote hasn't seen.
    await dbB.upsertRating(LocalRatingsCompanion(
      id: const Value('auth-uuid_spotify:a'),
      userId: const Value('auth-uuid'),
      itemId: const Value('spotify:a'),
      elo: const Value(1300),
      comparisons: const Value(5),
      updatedAt: Value(DateTime.now().add(const Duration(hours: 1))),
    ));

    await repoB.pullRemote(); // remote is older — must keep the local edit
    final a = (await repoB.loadLibrary()).firstWhere((i) => i.id == 'spotify:a');
    expect(a.elo, 1300);
    expect(a.comparisons, 5);
  });

  test('removeItem deletes the rating locally and remotely', () async {
    await repo.addItem(_item('spotify:a', 'A'));
    await repo.addItem(_item('spotify:b', 'B'));
    await repo.recordComparison(winnerId: 'spotify:a', loserId: 'spotify:b');
    await pumpEventQueue(); // let the setup pushes reach the remote first
    expect((await repo.loadLibrary()).length, 2);

    await repo.removeItem('spotify:a');
    await pumpEventQueue(); // then let the detached remote delete flush

    final local = await repo.loadLibrary();
    expect(local.map((i) => i.id), ['spotify:b']);
    final remoteRatings = await remote.getRatings('auth-uuid');
    expect(remoteRatings.map((r) => r['item_id']).toList(),
        isNot(contains('uuid-0')));
    expect(remote.comparisons, isEmpty); // the a/b comparison was removed
  });

  test('resetForPlacement restores starting elo and clears comparisons', () async {
    await repo.addItem(_item('spotify:a', 'A'));
    await repo.addItem(_item('spotify:b', 'B'));
    await repo.recordComparison(winnerId: 'spotify:a', loserId: 'spotify:b');
    await pumpEventQueue(); // setup pushes reach the remote first
    final winner =
        (await repo.loadLibrary()).firstWhere((i) => i.id == 'spotify:a');
    expect(winner.elo, greaterThan(1000));
    expect(winner.comparisons, 1);

    await repo.resetForPlacement('spotify:a');
    await pumpEventQueue(); // then the detached remote comparison-clear flushes

    final a = (await repo.loadLibrary()).firstWhere((i) => i.id == 'spotify:a');
    expect(a.elo, 1000);
    expect(a.comparisons, 0);
    expect(remote.comparisons, isEmpty);
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
