import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/services/reading_time_calculator.dart';

void main() {
  group('ReadingTimeCalculator', () {
    test('bo\'sh matn uchun ham minimal vaqt qaytadi', () {
      final duration = ReadingTimeCalculator.forText('');
      expect(duration.inSeconds, ReadingTimeCalculator.minimumSeconds);
    });

    test('juda qisqa matn uchun minimal vaqtdan kam bo\'lmaydi', () {
      final duration = ReadingTimeCalculator.forText('Salom dunyo');
      expect(
        duration.inSeconds,
        greaterThanOrEqualTo(ReadingTimeCalculator.minimumSeconds),
      );
    });

    test('uzun matn uchun so\'z soniga mos vaqt hisoblanadi', () {
      // 220 so'z/daqiqa tezlikda 440 so'z = 2 daqiqa = 120 soniya.
      final words = List.generate(440, (_) => 'so\'z').join(' ');
      final duration = ReadingTimeCalculator.forText(words);
      expect(duration.inSeconds, closeTo(120, 2));
    });

    test('matn uzunroq bo\'lsa, vaqt ham ko\'proq bo\'ladi (monoton)', () {
      final short = ReadingTimeCalculator.forText(
        List.generate(50, (_) => 'so\'z').join(' '),
      );
      final long = ReadingTimeCalculator.forText(
        List.generate(500, (_) => 'so\'z').join(' '),
      );
      expect(long.inSeconds, greaterThan(short.inSeconds));
    });
  });
}
