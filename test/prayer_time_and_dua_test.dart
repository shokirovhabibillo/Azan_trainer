import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/azon_dua_content.dart';
import 'package:azon_trainer/models/prayer_time.dart';

void main() {
  group('PrayerTime — v1.22 (Bomdod qo\'shildi)', () {
    test('endi 5 ta namoz vaqti mavjud (Bomdod bilan)', () {
      expect(PrayerTime.values.length, 5);
    });

    test('Bomdod uchun label va isBomdod to\'g\'ri', () {
      expect(PrayerTime.bomdod.label, 'Bomdod');
      expect(PrayerTime.bomdod.isBomdod, isTrue);
    });

    test('qolgan 4 namoz uchun isBomdod = false', () {
      for (final time in [
        PrayerTime.peshin,
        PrayerTime.asr,
        PrayerTime.shom,
        PrayerTime.xufton,
      ]) {
        expect(
          time.isBomdod,
          isFalse,
          reason: '${time.label} uchun isBomdod false bo\'lishi kerak',
        );
      }
    });

    test('har bir namoz vaqtining o\'zbekcha nomi bor', () {
      expect(PrayerTime.peshin.label, 'Peshin');
      expect(PrayerTime.asr.label, 'Asr');
      expect(PrayerTime.shom.label, 'Shom');
      expect(PrayerTime.xufton.label, 'Xufton');
    });
  });

  group('AzonDuaContent — v1.22', () {
    test('barcha maydonlar bo\'sh emas', () {
      expect(AzonDuaContent.arabicText, isNotEmpty);
      expect(AzonDuaContent.transliteration, isNotEmpty);
      expect(AzonDuaContent.meaningUz, isNotEmpty);
      expect(AzonDuaContent.sourceNote, isNotEmpty);
    });

    test('arabcha matn arab harflaridan iborat', () {
      final hasArabicChar = AzonDuaContent.arabicText.runes.any(
        (r) => r >= 0x0600 && r <= 0x06FF,
      );
      expect(hasArabicChar, isTrue);
    });
  });
}
