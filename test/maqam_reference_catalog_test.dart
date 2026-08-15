import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/maqam_reference_catalog.dart';
import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/models/maqam.dart';

void main() {
  const expectedMaqamOrder = [
    Maqam.bayati,
    Maqam.ajam,
    Maqam.kurd,
    Maqam.hijaz,
    Maqam.lami,
    Maqam.nahawand,
    Maqam.rast,
    Maqam.saba,
  ];

  const allCoveredPhraseIds = [
    'azon_allohu_akbar',
    'azon_ashhadu_laa_ilaaha',
    'azon_ashhadu_anna_muhammadan',
    'azon_hayya_alas_solah',
    'azon_hayya_alal_falah',
    'azon_allohu_akbar_closing',
    'azon_laa_ilaaha_illalloh',
    'bomdod_assolatu_khoyrum_minan_navm',
  ];

  group('MaqamReferenceCatalog — v1.17 (8 maqom x 8 jumla)', () {
    test(
        'azon_allohu_akbar uchun barcha 8 ta maqom mavjud, to\'g\'ri '
        'tartibda', () {
      final variants =
          MaqamReferenceCatalog.variantsFor('azon_allohu_akbar');
      expect(variants.length, 8);
      expect(variants.map((v) => v.maqam), expectedMaqamOrder);
    });

    test(
        'azon_laa_ilaaha_illalloh ham endi 8 ta variantga ega '
        '(v1.17 to\'liq to\'plam)', () {
      final variants =
          MaqamReferenceCatalog.variantsFor('azon_laa_ilaaha_illalloh');
      expect(variants.length, 8);
    });

    test('Bomdod qo\'shimchasi (as-solaatu) ham 8 ta maqomga ega', () {
      final variants = MaqamReferenceCatalog.variantsFor(
        'bomdod_assolatu_khoyrum_minan_navm',
      );
      expect(variants.length, 8);
    });

    test('barcha 8 jumla uchun aynan 8 tadan variant bor', () {
      for (final id in allCoveredPhraseIds) {
        expect(
          MaqamReferenceCatalog.variantsFor(id).length,
          8,
          reason: '$id uchun 8 ta variant kutilgan edi',
        );
        expect(MaqamReferenceCatalog.hasMultipleVariants(id), isTrue);
      }
    });

    test(
        'fayl yo\'llari to\'g\'ri papka strukturasiga mos '
        '(maqamat/phrases/{maqom}/...)', () {
      final bayatiVariant = MaqamReferenceCatalog.variantForMaqam(
        'azon_allohu_akbar',
        Maqam.bayati,
      );
      expect(
        bayatiVariant?.audioFile,
        'maqamat/phrases/bayati/allohu_akbar.wav',
      );

      final sabaVariant = MaqamReferenceCatalog.variantForMaqam(
        'bomdod_assolatu_khoyrum_minan_navm',
        Maqam.saba,
      );
      expect(
        sabaVariant?.audioFile,
        'maqamat/phrases/saba/as_solaatu_khayrun_minan_nawm.wav',
      );
    });

    test(
        'variantForMaqam mavjud bo\'lmagan maqom uchun null qaytaradi',
        () {
      // Iqomat jumlalari uchun hech qanday maqom variantlari yo'q.
      final result = MaqamReferenceCatalog.variantForMaqam(
        'iqomat_allohu_akbar_opening',
        Maqam.bayati,
      );
      expect(result, isNull);
    });

    test('mavjud bo\'lmagan jumla uchun bo\'sh ro\'yxat qaytadi', () {
      expect(MaqamReferenceCatalog.variantsFor('nomavjud_id'), isEmpty);
    });
  });

  group('Phrase.copyWithReference', () {
    test(
        'faqat referenceAudioFile va maqam o\'zgaradi, boshqa hamma '
        'narsa saqlanadi', () {
      final original = PhraseCatalog.byId('azon_allohu_akbar');
      final copy = original.copyWithReference(
        referenceAudioFile: 'maqamat/phrases/kurd/allohu_akbar.wav',
        maqam: Maqam.kurd,
      );

      expect(copy.id, original.id);
      expect(copy.category, original.category);
      expect(copy.arabicText, original.arabicText);
      expect(copy.transliteration, original.transliteration);
      expect(copy.meaningUz, original.meaningUz);
      expect(copy.repeatCount, original.repeatCount);

      expect(
        copy.referenceAudioFile,
        'maqamat/phrases/kurd/allohu_akbar.wav',
      );
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
