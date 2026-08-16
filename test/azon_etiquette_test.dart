import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/azon_etiquette_content.dart';
import 'package:azon_trainer/data/phrase_etiquette_hints.dart';

void main() {
  group('phraseEtiquetteHints', () {
    test('"Hayya alas-solah" (Azon) uchun o\'ng tomon eslatmasi bor', () {
      final hint = phraseEtiquetteHints['azon_hayya_alas_solah'];
      expect(hint, isNotNull);
      expect(hint!.text, contains('O\'ng'));
    });

    test('"Hayya alal-falah" (Azon) uchun chap tomon eslatmasi bor', () {
      final hint = phraseEtiquetteHints['azon_hayya_alal_falah'];
      expect(hint, isNotNull);
      expect(hint!.text, contains('Chap'));
    });

    test('Iqomatdagi mos jumlalar uchun ham eslatma bor', () {
      expect(
        phraseEtiquetteHints['iqomat_hayya_alas_solah']?.text,
        contains('O\'ng'),
      );
      expect(
        phraseEtiquetteHints['iqomat_hayya_alal_falah']?.text,
        contains('Chap'),
      );
    });

    test('boshqa jumlalar uchun eslatma yo\'q', () {
      expect(phraseEtiquetteHints['azon_allohu_akbar'], isNull);
      expect(phraseEtiquetteHints['azon_laa_ilaaha_illalloh'], isNull);
    });
  });

  group('azonEtiquetteItems', () {
    test('4 ta bo\'lim mavjud', () {
      expect(azonEtiquetteItems.length, 4);
    });

    test('har bir bo\'limda sarlavha va matn bo\'sh emas', () {
      for (final item in azonEtiquetteItems) {
        expect(item.title, isNotEmpty);
        expect(item.body, isNotEmpty);
      }
    });
  });
}
