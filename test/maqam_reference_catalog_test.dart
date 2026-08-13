import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/maqam_reference_catalog.dart';
import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/models/maqam.dart';

void main() {
  group('MaqamReferenceCatalog', () {
    test(
        'azon_allohu_akbar uchun 4 ta variant '
        '(Bayati, Lami, Kurd, Hijaz)', () {
      final variants =
          MaqamReferenceCatalog.variantsFor('azon_allohu_akbar');
      expect(variants.length, 4);
      expect(variants.map((v) => v.maqam), [
        Maqam.bayati,
        Maqam.lami,
        Maqam.kurd,
        Maqam.hijaz,
      ]);
    });

    test(
        'azon_laa_ilaaha_illalloh uchun qo\'shimcha variant yo\'q '
        '(faqat standart Bayati)', () {
      final variants =
          MaqamReferenceCatalog.variantsFor('azon_laa_ilaaha_illalloh');
      expect(variants, isEmpty);
      expect(
        MaqamReferenceCatalog.hasMultipleVariants(
          'azon_laa_ilaaha_illalloh',
        ),
        isFalse,
      );
    });

    test('mavjud bo\'lmagan jumla uchun bo\'sh ro\'yxat qaytadi', () {
      expect(MaqamReferenceCatalog.variantsFor('nomavjud_id'), isEmpty);
    });

    test(
        'barcha 6 ta ko\'p-variantli Azon jumlasi uchun aynan 4 tadan '
        'variant bor', () {
      const multiVariantIds = [
        'azon_allohu_akbar',
        'azon_ashhadu_laa_ilaaha',
        'azon_ashhadu_anna_muhammadan',
        'azon_hayya_alas_solah',
        'azon_hayya_alal_falah',
        'azon_allohu_akbar_closing',
      ];
      for (final id in multiVariantIds) {
        expect(
          MaqamReferenceCatalog.variantsFor(id).length,
          4,
          reason: '$id uchun 4 ta variant kutilgan edi',
        );
        expect(MaqamReferenceCatalog.hasMultipleVariants(id), isTrue);
      }
    });
  });

  group('Phrase.copyWithReference', () {
    test(
        'faqat referenceAudioFile va maqam o\'zgaradi, boshqa hamma '
        'narsa saqlanadi', () {
      final original = PhraseCatalog.byId('azon_allohu_akbar');
      final copy = original.copyWithReference(
        referenceAudioFile: 'azon_allohu_akbar_kurd.wav',
        maqam: Maqam.kurd,
      );

      expect(copy.id, original.id);
      expect(copy.category, original.category);
      expect(copy.arabicText, original.arabicText);
      expect(copy.transliteration, original.transliteration);
      expect(copy.meaningUz, original.meaningUz);
      expect(copy.repeatCount, original.repeatCount);

      expect(copy.referenceAudioFile, 'azon_allohu_akbar_kurd.wav');
      expect(copy.maqam, Maqam.kurd);

      // Original o'zgarmagan (immutable).
      expect(original.referenceAudioFile, 'azon_allohu_akbar.wav');
      expect(original.maqam, Maqam.bayati);
    });
  });

  group('v1.10: Iqomat transkripsiyasi tuzatildi', () {
    test(
        'iqomat_qad_qomatis_solah transliteratsiyasi "Qod" bilan '
        'boshlanadi', () {
      final phrase = PhraseCatalog.byId('iqomat_qad_qomatis_solah');
      expect(phrase.transliteration, 'Qod qoomatis-solaah');
    });
  });
}
