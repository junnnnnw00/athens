import 'package:athens/features/profile/profile_service.dart';
import 'package:athens/i18n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileService.validateHandle', () {
    test('accepts a valid lowercase handle', () {
      expect(ProfileService.validateHandle('junwoo_00', AppLanguage.en), isNull);
    });

    test('rejects too short', () {
      expect(ProfileService.validateHandle('ab', AppLanguage.en), isNotNull);
    });

    test('rejects too long (>20)', () {
      expect(ProfileService.validateHandle('a' * 21, AppLanguage.en), isNotNull);
    });

    test('rejects uppercase and symbols', () {
      expect(ProfileService.validateHandle('JunWoo', AppLanguage.en), isNotNull);
      expect(ProfileService.validateHandle('jun woo', AppLanguage.en), isNotNull);
      expect(ProfileService.validateHandle('jun-woo', AppLanguage.en), isNotNull);
      expect(ProfileService.validateHandle('jun.woo', AppLanguage.en), isNotNull);
    });

    test('accepts digits and underscores', () {
      expect(ProfileService.validateHandle('a_1_b_2', AppLanguage.en), isNull);
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
      });
      expect(p.handle, 'junwoo');
      expect(p.displayName, '준우');
      expect(p.isPublic, isTrue);
    });

    test('defaults missing bools to false', () {
      final p = UserProfile.fromMap({'id': 'u1', 'handle': 'x'});
      expect(p.isPublic, isFalse);
    });

    test('maps lastfm_username correctly', () {
      final p = UserProfile.fromMap({
        'id': 'u1',
        'handle': 'junwoo',
        'lastfm_username': 'junwoo_fm',
      });
      expect(p.lastfmUsername, 'junwoo_fm');
    });
  });
}
