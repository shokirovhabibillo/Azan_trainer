import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/maqam_reference_catalog.dart';
import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/models/maqam.dart';

/// v1.18: `FullAdhanPreviewScreen`ning ketma-ket ijro rejimi
/// `PhraseCatalog.azonSequence()` (jumlalar tartibi) va
/// `MaqamReferenceCatalog` (har biriga mos audio) ustiga quriladi.
/// Bu test o'sha ikkala manbaning BIRGALIKDA to'g'ri natija
/// berishini — screen widgetini yaratmasdan — tasdiqlaydi.
void main() {
  List<String> sequentialFilesFor(Maqam maqam, {required bool isBomdod}) {
    final phrases = PhraseCatalog.azonSequence(isBomdod: isBomdod);
    return phrases
        .map(
          (p) => MaqamReferenceCatalog.variantForMaqam(p.id, maqam)?.audioFile,
        )
        .whereType<String>()
        .toList();
  }

  group('Ketma-ket ijro uchun fayl ro\'yxati', () {
    test('oddiy Azon uchun Bayati — 7 ta fayl, to\'g\'ri tartibda', () {
      final files = sequentialFilesFor(Maqam.bayati, isBomdod: false);

      expect(files.length, 7);
      expect(files, [
        'maqamat/phrases/bayati/allohu_akbar.wav',
        'maqamat/phrases/bayati/ashhadu_laa_ilaaha.wav',
        'maqamat/phrases/bayati/ashhadu_anna_muhammadan.wav',
        'maqamat/phrases/bayati/hayya_alas_solah.wav',
        'maqamat/phrases/bayati/hayya_alal_falah.wav',
        'maqamat/phrases/bayati/allohu_akbar_closing.wav',
        'maqamat/phrases/bayati/laa_ilaaha_illalloh.wav',
      ]);
    });

    test(
        'Bomdod uchun Saba — 8 ta fayl (as-solaatu bilan), to\'g\'ri '
        'joyda', () {
      final files = sequentialFilesFor(Maqam.saba, isBomdod: true);

      expect(files.length, 8);
      expect(
        files[5],
        'maqamat/phrases/saba/as_solaatu_khayrun_minan_nawm.wav',
      );
      expect(
        files[6],
        'maqamat/phrases/saba/allohu_akbar_closing.wav',
      );
    });

    test(
        'barcha 8 maqom uchun oddiy Azon ketma-ketligi to\'liq (7/7)',
        () {
      for (final maqam in [
        Maqam.bayati,
        Maqam.ajam,
        Maqam.kurd,
        Maqam.hijaz,
        Maqam.lami,
        Maqam.nahawand,
        Maqam.rast,
        Maqam.saba,
      ]) {
        final files = sequentialFilesFor(maqam, isBomdod: false);
        expect(
          files.length,
          7,
          reason: '${maqam.label} uchun 7 ta fayl kutilgan edi',
        );
      }
    });
  });
}
