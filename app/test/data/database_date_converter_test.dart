import 'package:flutter_test/flutter_test.dart';
import 'package:athens/data/local/app_database.dart';

void main() {
  group('DateTimeCorrectionConverter tests', () {
    const converter = DateTimeCorrectionConverter();

    test('should pass normal 2026 dates without modification', () {
      final normalDate = DateTime(2026, 6, 2, 12, 34, 56);
      final corrected = converter.fromSql(normalDate);
      expect(corrected.year, 2026);
      expect(corrected.month, 6);
      expect(corrected.day, 2);
      expect(corrected.hour, 12);
      expect(corrected.minute, 34);
    });

    test('should correct 1970 unit-error dates back to 2026', () {
      // 1780132586 is seconds since epoch for approx 2026-05-30.
      // But if parsed as milliseconds, it becomes 1970-01-21 14:28:52.586.
      final bugDate = DateTime.fromMillisecondsSinceEpoch(1780132586);
      expect(bugDate.year, 1970);

      final corrected = converter.fromSql(bugDate);
      expect(corrected.year, 2026);
      
      final expectedDate = DateTime.fromMillisecondsSinceEpoch(1780132586000).toLocal();
      expect(corrected, expectedDate);
    });

    test('toSql returns the input DateTime unmodified', () {
      final now = DateTime.now();
      expect(converter.toSql(now), now);
    });
  });
}
