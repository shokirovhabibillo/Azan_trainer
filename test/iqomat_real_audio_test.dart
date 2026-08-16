import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/services/audio/reference_audio_checker.dart';
import 'package:azon_trainer/services/audio/reference_audio_loader.dart';

/// v1.15: Iqomat uchun HAQIQIY reference audio fayllari (foydalanuvchi
/// tomonidan segmentlangan, `assets/audio/`ga qo'shilgan) — endi FAKE
/// emas, real `ReferenceAudioChecker`/`ReferenceAudioLoader` orqali
/// tekshiriladi. Bu test pubspec.yaml'dagi asset e'loni va fayl
/// nomlarining to'g'ri mos kelishini ushlab qoladi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const checker = ReferenceAudioChecker();
  const loader = ReferenceAudioLoader();

  group('v1.15: Iqomat — haqiqiy reference audio', () {
    test(
        'barcha 8 ta Iqomat jumlasi uchun reference fayl HAQIQATAN '
        'assets ichida mavjud', () async {
      for (final phrase in PhraseCatalog.iqomat) {
        final exists = await checker.exists(phrase.referenceAudioFile);
        expect(
          exists,
          isTrue,
          reason:
              '${phrase.id} (${phrase.referenceAudioFile}) assets ichida '
              'topilmadi',
        );
      }
    });

    test(
        'birinchi (ochish takbiri) fayli haqiqatan WAV sifatida '
        'dekodlanadi', () async {
      final phrase = PhraseCatalog.byId('iqomat_allohu_akbar_opening');
      final decoded = await loader.load(phrase.referenceAudioFile);

      expect(decoded.sampleRate, 16000);
      expect(decoded.channels, 1);
      expect(decoded.samples, isNotEmpty);
      // Taxminan 8 soniya (foydalanuvchi bergan ma'lumot bo'yicha).
      expect(decoded.durationSeconds, closeTo(8.0, 0.5));
    });

    test(
        '"Qod qoomatis-solaah" fayli ham haqiqatan mavjud va dekodlanadi',
        () async {
      final phrase = PhraseCatalog.byId('iqomat_qad_qomatis_solah');
      final decoded = await loader.load(phrase.referenceAudioFile);

      expect(decoded.samples, isNotEmpty);
      expect(decoded.durationSeconds, closeTo(5.7, 0.5));
    });

    test(
        'barcha 8 fayl davomiyliklari yig\'indisi asl audio bilan mos '
        '(~43.5s)', () async {
      double total = 0;
      for (final phrase in PhraseCatalog.iqomat) {
        final decoded = await loader.load(phrase.referenceAudioFile);
        total += decoded.durationSeconds;
      }
      expect(total, closeTo(43.5, 1.0));
    });
  });
}
