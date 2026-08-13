import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/models/analysis_result.dart';
import 'package:azon_trainer/models/duration_comparison_result.dart';
import 'package:azon_trainer/models/phrase_practice_state.dart';
import 'package:azon_trainer/models/reference_comparison_result.dart';
import 'package:azon_trainer/services/practice_session_controller.dart';

/// v1.7: `PracticeSessionController` — jumla ID bo'yicha recording/
/// tahlil holatini saqlaydigan sof Dart controller — uchun testlar.
///
/// MUHIM: bu testlar `PracticeScreen`/`PhrasePracticeScreen` widget'
/// larini emas, balki ular ORQALI ishlatiladigan asosiy MANTIQNI
/// (controller) sinaydi — chunki widget'lar haqiqiy mikrofon/fayl
/// tizimi platform-kanallariga bog'liq (`AudioRecorderService`),
/// bularni to'liq widget-test qilish uchun qo'shimcha
/// dependency-injection refactoring kerak bo'lardi (v1.7 "minimal fix"
/// doirasidan tashqarida). Controllerning o'zi — butun tuzatishning
/// yuragi — to'liq, mustaqil test qilingan.
void main() {
  AnalysisResult dummyAnalysis() {
    return AnalysisResult(
      pitch: const MetricResult.notConnected('Pitch'),
      duration: const MetricResult.notConnected('Duration'),
      createdAt: DateTime.now(),
      referenceComparison: const ReferenceComparisonResult.notAvailable(),
    );
  }

  DurationComparisonResult dummyDuration() {
    return DurationComparisonResult.notAvailable();
  }

  group('Test 1: jumlalar orasida o\'tib qaytish - recording saqlanadi', () {
    test('1/7 da recording -> 2/7 ga o\'tish -> 1/7 ga qaytish -> '
        'recording hali ham mavjud', () {
      final controller = PracticeSessionController();

      // 1/7 da yozib olindi.
      controller.update(
        'phrase_1',
        const PhrasePracticeState(
          recordingPath: '/tmp/phrase_1.wav',
          recordingDuration: Duration(seconds: 3),
        ),
      );

      // 2/7 ga o'tildi (bu shunchaki index o'zgarishi — controllerga
      // ta'sir qilmaydi, chunki hech narsa update qilinmadi).
      // 1/7 ga qaytildi.
      final restored = controller.stateFor('phrase_1');

      expect(restored, isNotNull);
      expect(restored!.hasRecording, isTrue);
      expect(restored.recordingPath, '/tmp/phrase_1.wav');
      expect(restored.recordingDuration, const Duration(seconds: 3));
    });
  });

  group('Test 2: ikkita jumla recordingi aralashmasligi', () {
    test('1/7 recording, 2/7 recording -> 1/7 ga qaytish -> aynan 1/7 '
        'audio qaytadi, 2/7 bilan aralashmaydi', () {
      final controller = PracticeSessionController();

      controller.update(
        'phrase_1',
        const PhrasePracticeState(
          recordingPath: '/tmp/phrase_1.wav',
          recordingDuration: Duration(seconds: 2),
        ),
      );
      controller.update(
        'phrase_2',
        const PhrasePracticeState(
          recordingPath: '/tmp/phrase_2.wav',
          recordingDuration: Duration(seconds: 5),
        ),
      );

      final phrase1State = controller.stateFor('phrase_1');
      final phrase2State = controller.stateFor('phrase_2');

      expect(phrase1State!.recordingPath, '/tmp/phrase_1.wav');
      expect(phrase1State.recordingDuration, const Duration(seconds: 2));

      expect(phrase2State!.recordingPath, '/tmp/phrase_2.wav');
      expect(phrase2State.recordingDuration, const Duration(seconds: 5));

      // Ikkalasi ham bir vaqtda, mustaqil mavjud — biri ikkinchisini
      // "ustidan yozmagan".
      expect(phrase1State.recordingPath, isNot(phrase2State.recordingPath));
    });
  });

  group('Test 3: tahlil natijasi jumla bilan bog\'lanib saqlanadi', () {
    test('Phrase tahlil qilindi -> boshqa phrase -> qaytish -> tahlil '
        'natijasi saqlangan holda qaytadi', () {
      final controller = PracticeSessionController();
      final analysis = dummyAnalysis();
      final duration = dummyDuration();

      controller.update(
        'azon_laa_ilaaha_illalloh',
        PhrasePracticeState(
          recordingPath: '/tmp/laa_ilaaha.wav',
          recordingDuration: const Duration(seconds: 4),
          analysisResult: analysis,
          durationResult: duration,
        ),
      );

      // Boshqa jumlaga "o'tildi" (controllerda alohida yozuv).
      controller.update(
        'azon_allohu_akbar',
        const PhrasePracticeState(
          recordingPath: '/tmp/allohu_akbar.wav',
          recordingDuration: Duration(seconds: 2),
        ),
      );

      // "Laa ilaaha illalloh"ga qaytildi.
      final restored = controller.stateFor('azon_laa_ilaaha_illalloh');

      expect(restored, isNotNull);
      expect(restored!.hasAnalysis, isTrue);
      expect(restored.analysisResult, same(analysis));
      expect(restored.durationResult, same(duration));
    });
  });

  group('Test 4: qayta yozish eski recordingni almashtiradi', () {
    test('Recording -> qayta recording -> eski o\'rniga yangisi turadi',
        () {
      final controller = PracticeSessionController();

      controller.update(
        'phrase_1',
        const PhrasePracticeState(
          recordingPath: '/tmp/old.wav',
          recordingDuration: Duration(seconds: 3),
        ),
      );

      // "Qayta yozish" bosilganda PhrasePracticeScreen avval null
      // yuboradi (holat tozalanadi)...
      controller.update('phrase_1', null);
      expect(controller.stateFor('phrase_1'), isNull);

      // ...keyin yangi recording tugagach, yangi holat yoziladi.
      controller.update(
        'phrase_1',
        const PhrasePracticeState(
          recordingPath: '/tmp/new.wav',
          recordingDuration: Duration(seconds: 5),
        ),
      );

      final restored = controller.stateFor('phrase_1');
      expect(restored!.recordingPath, '/tmp/new.wav');
      expect(restored.recordingDuration, const Duration(seconds: 5));
      expect(restored.recordingPath, isNot('/tmp/old.wav'));
    });

    test('withNewRecording eski tahlil natijasini bekor qiladi', () {
      final analysis = dummyAnalysis();
      final duration = dummyDuration();
      final withAnalysis = PhrasePracticeState(
        recordingPath: '/tmp/old.wav',
        recordingDuration: const Duration(seconds: 3),
        analysisResult: analysis,
        durationResult: duration,
      );
      expect(withAnalysis.hasAnalysis, isTrue);

      final afterReRecord = withAnalysis.withNewRecording(
        recordingPath: '/tmp/new.wav',
        recordingDuration: const Duration(seconds: 4),
      );

      expect(afterReRecord.recordingPath, '/tmp/new.wav');
      expect(afterReRecord.hasAnalysis, isFalse);
    });
  });

  group('Test 5: Azon 7/7 va Bomdod 8/8 ketma-ketligi o\'zgarmagan', () {
    test('Oddiy azon 7 ta jumladan iborat', () {
      final sequence = PhraseCatalog.azonSequence(isBomdod: false);
      expect(sequence.length, 7);
      expect(sequence.last.id, 'azon_laa_ilaaha_illalloh');
      expect(sequence[5].id, 'azon_allohu_akbar_closing');
    });

    test('Bomdod azoni 8 ta jumladan iborat', () {
      final sequence = PhraseCatalog.azonSequence(isBomdod: true);
      expect(sequence.length, 8);
      expect(sequence.last.id, 'azon_laa_ilaaha_illalloh');
      expect(
        sequence[5].id,
        'bomdod_assolatu_khoyrum_minan_navm',
      );
      expect(sequence[6].id, 'azon_allohu_akbar_closing');
    });

    test('v1.8: Iqomat 8 ta jumladan iborat, to\'g\'ri tartibda', () {
      const iqomat = PhraseCatalog.iqomat;
      expect(iqomat.length, 8);

      final ids = iqomat.map((p) => p.id).toList();
      expect(ids, [
        'iqomat_allohu_akbar_opening',
        'iqomat_ashhadu_laa_ilaaha',
        'iqomat_ashhadu_anna_muhammadan',
        'iqomat_hayya_alas_solah',
        'iqomat_hayya_alal_falah',
        'iqomat_qad_qomatis_solah',
        'iqomat_allohu_akbar_closing',
        'iqomat_laa_ilaaha_illalloh',
      ]);

      // Ochish/yopish takbiri va "Qad qoomatis-solaah" 2 martadan,
      // qolganlari 1 martadan (Azondan farqli).
      expect(iqomat[0].repeatCount, 2); // opening takbir
      expect(iqomat[1].repeatCount, 1);
      expect(iqomat[2].repeatCount, 1);
      expect(iqomat[3].repeatCount, 1);
      expect(iqomat[4].repeatCount, 1);
      expect(iqomat[5].repeatCount, 2); // Qad qoomatis-solaah
      expect(iqomat[6].repeatCount, 2); // closing takbir
      expect(iqomat[7].repeatCount, 1);
    });
  });

  group('Qo\'shimcha: bo\'sh/mavjud bo\'lmagan holatlar', () {
    test('Yozilmagan jumla uchun stateFor null qaytaradi', () {
      final controller = PracticeSessionController();
      expect(controller.stateFor('never_recorded'), isNull);
    });

    test('recordedCount va analyzedCount to\'g\'ri hisoblanadi', () {
      final controller = PracticeSessionController();
      controller.update(
        'p1',
        const PhrasePracticeState(
          recordingPath: '/tmp/p1.wav',
          recordingDuration: Duration(seconds: 1),
        ),
      );
      controller.update(
        'p2',
        PhrasePracticeState(
          recordingPath: '/tmp/p2.wav',
          recordingDuration: const Duration(seconds: 1),
          analysisResult: dummyAnalysis(),
          durationResult: dummyDuration(),
        ),
      );

      expect(controller.recordedCount, 2);
      expect(controller.analyzedCount, 1);
    });
  });
}
