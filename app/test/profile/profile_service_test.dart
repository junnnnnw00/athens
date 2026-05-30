import 'package:athens/features/profile/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileService.validateHandle', () {
    test('accepts a valid lowercase handle', () {
      expect(ProfileService.validateHandle('junwoo_00'), isNull);
    });

    test('rejects too short', () {
      expect(ProfileService.validateHandle('ab'), isNotNull);
    });

    test('rejects too long (>20)', () {
      expect(ProfileService.validateHandle('a' * 21), isNotNull);
    });

    test('rejects uppercase and symbols', () {
      expect(ProfileService.validateHandle('JunWoo'), isNotNull);
      expect(ProfileService.validateHandle('jun woo'), isNotNull);
      expect(ProfileService.validateHandle('jun-woo'), isNotNull);
      expect(ProfileService.validateHandle('jun.woo'), isNotNull);
    });

    test('accepts digits and underscores', () {
      expect(ProfileService.validateHandle('a_1_b_2'), isNull);
    });
  });

  group('UserProfile.fromMap', () {
    test('maps fields with sensible defaults', () {
      final p = UserProfile.fromMap({
        'id': 'u1',
        'handle': 'junwoo',
        'display_name': '준우',
        'bio': null,
        'is_public': true,
        'spotify_enabled': false,
      });
      expect(p.handle, 'junwoo');
      expect(p.displayName, '준우');
      expect(p.isPublic, isTrue);
      expect(p.spotifyEnabled, isFalse);
    });

    test('defaults missing bools to false', () {
      final p = UserProfile.fromMap({'id': 'u1', 'handle': 'x'});
      expect(p.isPublic, isFalse);
      expect(p.spotifyEnabled, isFalse);
    });
  });
}
