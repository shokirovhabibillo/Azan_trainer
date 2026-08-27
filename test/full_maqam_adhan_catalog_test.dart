import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/full_maqam_adhan_catalog.dart';
import 'package:azon_trainer/models/maqam.dart';

void main() {
  group('FullMaqamAdhanCatalog — v1.18 (ongli ravishda bo\'shatilgan)', () {
    test(
        'hozircha bo\'sh — full/ fayllari hajm sababli olib '
        'tashlangan', () {
      expect(FullMaqamAdhanCatalog.all, isEmpty);
    });

    test(
        'audioFileFor har qanday maqom uchun null qaytaradi (hozircha)',
        () {
      for (final maqam in Maqam.values) {
        expect(FullMaqamAdhanCatalog.audioFileFor(maqam), isNull);
      }
    });
  });
}
