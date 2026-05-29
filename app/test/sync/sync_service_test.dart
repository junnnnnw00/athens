import 'package:flutter_test/flutter_test.dart';
import 'package:athens/data/sync/sync_service.dart';

import '../fakes/fakes.dart';

void main() {
  group('SyncService', () {
    late FakeSupabaseGateway gateway;
    late SyncService svc;

    setUp(() {
      gateway = FakeSupabaseGateway();
      svc = SyncService(gateway: gateway);
    });

    test('uploads local ratings to gateway', () async {
      final local = [
        {'item_id': 'item-1', 'elo': 1050.0, 'comparisons': 3},
        {'item_id': 'item-2', 'elo': 950.0, 'comparisons': 2},
      ];

      final result = await svc.sync(userId: 'user-1', localRatings: local);

      expect(result.uploaded, 2);
      expect(result.errors, isEmpty);

      final remote = await gateway.getRatings('user-1');
      expect(remote.length, 2);
    });

    test('downloads remote ratings', () async {
      await gateway.upsertRating({
        'user_id': 'user-1',
        'item_id': 'item-remote',
        'elo': 1100.0,
        'comparisons': 5,
      });

      final result = await svc.sync(userId: 'user-1', localRatings: []);

      expect(result.downloaded, 1);
    });

    test('returns zero counts for empty state', () async {
      final result = await svc.sync(userId: 'user-empty', localRatings: []);
      expect(result.uploaded, 0);
      expect(result.downloaded, 0);
      expect(result.errors, isEmpty);
    });

    test('syncs comparison to gateway', () async {
      await svc.syncComparison(
        userId: 'user-1',
        winnerId: 'item-a',
        loserId: 'item-b',
      );
      // No exception thrown = success (FakeGateway stores in memory).
    });

    test('handles multiple syncs — last write wins by overwriting', () async {
      await svc.sync(
        userId: 'user-1',
        localRatings: [
          {'item_id': 'item-1', 'elo': 1000.0, 'comparisons': 1},
        ],
      );
      await svc.sync(
        userId: 'user-1',
        localRatings: [
          {'item_id': 'item-1', 'elo': 1050.0, 'comparisons': 2},
        ],
      );
      final remote = await gateway.getRatings('user-1');
      expect(remote.length, 1);
      expect(remote.first['elo'], 1050.0);
    });
  });

  group('FakeSupabaseGateway', () {
    test('upserts and retrieves profile', () async {
      final gateway = FakeSupabaseGateway();
      await gateway.upsertProfile({'id': 'user-1', 'handle': 'testuser'});
      final profile = await gateway.getProfile('user-1');
      expect(profile, isNotNull);
      expect(profile!['handle'], 'testuser');
    });

    test('getProfile returns null for unknown user', () async {
      final gateway = FakeSupabaseGateway();
      expect(await gateway.getProfile('unknown'), isNull);
    });

    test('upserts review and retrieves it', () async {
      final gateway = FakeSupabaseGateway();
      await gateway.upsertReview({
        'user_id': 'u1',
        'item_id': 'i1',
        'body': 'Great track',
      });
      final reviews = await gateway.getReviews('u1');
      expect(reviews.length, 1);
      expect(reviews.first['body'], 'Great track');
    });
  });
}
