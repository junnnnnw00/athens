import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ============================================================================
// Tables
// ============================================================================

class LocalItems extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get source => text()();
  TextColumn get sourceId => text()();
  TextColumn get title => text()();
  TextColumn get primaryArtist => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalRatings extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get itemId => text()();
  RealColumn get elo => real().withDefault(const Constant(1000.0))();
  IntColumn get comparisons => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalComparisons extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get winnerItemId => text()();
  TextColumn get loserItemId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalReviews extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get itemId => text()();
  TextColumn get body => text()();
  RealColumn get ratingSnapshot => real().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// Database
// ============================================================================

@DriftDatabase(
    tables: [LocalItems, LocalRatings, LocalComparisons, LocalReviews])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await customStatement('UPDATE local_ratings SET elo = elo + 200.0;');
        }
      },
    );
  }

  // Items
  Future<List<LocalItem>> getAllItems() => select(localItems).get();

  Future<LocalItem?> getItemById(String id) =>
      (select(localItems)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<void> upsertItem(LocalItemsCompanion item) =>
      into(localItems).insertOnConflictUpdate(item);

  // Ratings
  Future<List<LocalRating>> getRatingsForUser(String userId) =>
      (select(localRatings)..where((r) => r.userId.equals(userId))).get();

  Future<void> upsertRating(LocalRatingsCompanion rating) =>
      into(localRatings).insertOnConflictUpdate(rating);

  Future<void> deleteRatingForItem(String userId, String itemId) =>
      (delete(localRatings)
            ..where((r) => r.userId.equals(userId) & r.itemId.equals(itemId)))
          .go();

  // Comparisons
  Future<void> insertComparison(LocalComparisonsCompanion comparison) =>
      into(localComparisons).insert(comparison);

  Future<List<LocalComparison>> getComparisonsForUser(String userId) =>
      (select(localComparisons)..where((c) => c.userId.equals(userId))).get();

  Future<void> deleteComparisonsForItem(String userId, String itemId) =>
      (delete(localComparisons)
            ..where((c) =>
                c.userId.equals(userId) &
                (c.winnerItemId.equals(itemId) | c.loserItemId.equals(itemId))))
          .go();

  Future<void> deleteReviewForItem(String userId, String itemId) =>
      (delete(localReviews)
            ..where((r) => r.userId.equals(userId) & r.itemId.equals(itemId)))
          .go();

  // Reviews
  Future<List<LocalReview>> getReviewsForUser(String userId) =>
      (select(localReviews)..where((r) => r.userId.equals(userId))).get();

  Future<void> upsertReview(LocalReviewsCompanion review) =>
      into(localReviews).insertOnConflictUpdate(review);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(
      name: 'athens_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  });
}
