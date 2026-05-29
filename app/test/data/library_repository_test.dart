import 'package:athens/data/local/app_database.dart';
import 'package:athens/data/repository/library_repository.dart';
import 'package:athens/features/catalog/catalog_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogItem _item(String id, String title, {List<CatalogTag> tags = const []}) =>
    CatalogItem(
      id: id,
      kind: 'album',
      title: title,
      primaryArtist: 'Artist $id',
      source: 'test',
      sourceId: id,
      tags: tags,
    );

void main() {
  late AppDatabase db;
  late LibraryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LibraryRepository(db: db, userId: 'u1');
  });

  tearDown(() => db.close());

  test('addItem persists an item at starting Elo and is idempotent', () async {
    await repo.addItem(_item('a', 'Loveless'));
    await repo.addItem(_item('a', 'Loveless')); // duplicate
    final lib = await repo.loadLibrary();
    expect(lib.length, 1);
    expect(lib.first.elo, 1000);
    expect(lib.first.comparisons, 0);
  });

  test('recordComparison updates Elo and reorders the library', () async {
    await repo.addItem(_item('a', 'A'));
    await repo.addItem(_item('b', 'B'));

    await repo.recordComparison(winnerId: 'b', loserId: 'a');

    final lib = await repo.loadLibrary();
    expect(lib.first.id, 'b'); // winner ranked first
    expect(lib.first.elo, greaterThan(1000));
    expect(lib.last.elo, lessThan(1000));
    expect(lib.every((i) => i.comparisons == 1), isTrue);
  });

  test('ranking survives an app "restart" (re-read from a fresh repo)',
      () async {
    await repo.addItem(_item('a', 'A'));
    await repo.addItem(_item('b', 'B'));
    await repo.addItem(_item('c', 'C'));
    await repo.recordComparison(winnerId: 'c', loserId: 'a');
    await repo.recordComparison(winnerId: 'c', loserId: 'b');

    // Simulate restart: brand-new repository against the SAME database.
    final repo2 = LibraryRepository(db: db, userId: 'u1');
    final lib = await repo2.loadLibrary();
    expect(lib.first.id, 'c');
    expect(lib.firstWhere((i) => i.id == 'c').comparisons, 2);
  });

  test('tags round-trip through persistence', () async {
    await repo.addItem(_item('a', 'A', tags: [
      const CatalogTag(name: 'shoegaze', source: 'genre'),
      const CatalogTag(name: 'dreamy', source: 'mood'),
    ]));
    final lib = await repo.loadLibrary();
    expect(lib.first.tags.map((t) => t.name),
        containsAll(['shoegaze', 'dreamy']));
  });

  test('reviews persist and are readable after restart', () async {
    await repo.addItem(_item('a', 'A'));
    await repo.upsertReview(itemId: 'a', body: '명반.', ratingSnapshot: 9.5);

    final repo2 = LibraryRepository(db: db, userId: 'u1');
    expect(await repo2.getReview('a'), '명반.');
  });

  test('rows are isolated per user', () async {
    await repo.addItem(_item('a', 'A'));
    final other = LibraryRepository(db: db, userId: 'u2');
    expect(await other.loadLibrary(), isEmpty);
  });
}
