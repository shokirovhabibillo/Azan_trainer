import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/models/analysis_result.dart';
import 'package:azon_trainer/models/duration_comparison_result.dart';
import 'package:azon_trainer/models/reference_comparison_result.dart';
import 'package:azon_trainer/services/analysis/duration_analyzer.dart';
import 'package:azon_trainer/services/analysis/pitch_analyzer.dart';
import 'package:azon_trainer/services/analysis/wav_decoder.dart';
import 'package:azon_trainer/services/audio/reference_audio_checker.dart';
import 'package:azon_trainer/services/audio/reference_audio_loader.dart';

import 'helpers/wav_test_helper.dart';

/// V2 FIX: bu fayl `PhraseCategory.iqomat` uchun pitch/duration/
/// reference pipeline'i AZON bilan bir xil, umumiy (kategoriyaga
/// bog'liq bo'lmagan) ekanligini isbotlaydi.
///
/// Haqiqiy Iqomat WAV fayllari hali `assets/audio/`da yo'q (audio
/// segmentatsiyasi jimlik-aniqlash orqali ishlamadi — bu haqda
/// yakuniy hisobotda batafsil yozilgan), shuning uchun bu yerda
/// avvalgi testlarda ishlatilgan xuddi shu fake checker/loader
/// pattern'i qo'llaniladi — bu haqiqiy fayl talab qilmasdan, butun
/// zanjirning KOD darajasida to'g'ri ishlashini tasdiqlaydi.

class _FakeCheckerAvailable extends ReferenceAudioChecker {
  const _FakeCheckerAvailable();
  @override
  Future<bool> exists(String assetFileName) async => true;
}

class _FakeCheckerUnavailable extends ReferenceAudioChecker {
  const _FakeCheckerUnavailable();
  @override
  Future<bool> exists(String assetFileName) async => false;
}

class _FakeLoader extends ReferenceAudioLoader {
  final Uint8List Function(String assetFileName) bytesProvider;
  _FakeLoader(this.bytesProvider);

  @override
  Future<DecodedAudio> load(String assetFileName) async {
    final bytes = bytesProvider(assetFileName);
    try {
      return const WavDecoder().decodeBytes(bytes);
    } on WavDecodeException catch (e) {
      throw ReferenceAudioLoadException(
        'Reference audio WAV formatida emas yoki buzilgan: ${e.message}',
      );
    }
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('azon_trainer_iqomat_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> writeTempWav(String name, List<int> bytes) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  group('V2 FIX: Iqomat pipeline Azon bilan bir xil (kategoriyaga '
      'bog\'liq emas)', () {
    test('1) Iqomat phrase ID -> referenceAudioFile to\'g\'ri belgilangan',
        () {
      for (final phrase in PhraseCatalog.iqomat) {
        expect(
          phrase.referenceAudioFile,
          isNotEmpty,
          reason: '${phrase.id} uchun referenceAudioFile bo\'sh bo\'lmasligi '
              'kerak',
        );
        expect(
          phrase.referenceAudioFile,
          startsWith('iqomat_'),
          reason: '${phrase.id} fayl nomi jumla ID bilan mos kelishi kerak',
        );
      }
    });

    test(
        '2/3) Iqomat + reference mavjud -> pitch, duration, reference '
        'comparison Azondagi kabi ishlaydi', () async {
      final phrase = PhraseCatalog.byId('iqomat_ashhadu_laa_ilaaha');

      final userWav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.2,
        toneHz: 200,
      );
      final refWav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.2,
        toneHz: 200,
      );
      final path = await writeTempWav('iqomat_user.wav', userWav);

      final pitchAnalyzer = PitchAnalyzer(
        referenceChecker: const _FakeCheckerAvailable(),
        referenceLoader: _FakeLoader((_) => refWav),
      );
      final durationAnalyzer = DurationAnalyzer(
        referenceChecker: const _FakeCheckerAvailable(),
        referenceLoader: _FakeLoader((_) => refWav),
      );

      final pitchResult = await pitchAnalyzer.analyze(
        recordingPath: path,
        referencePhrase: phrase,
      );
      final durationResult = await durationAnalyzer.analyze(
        recordingPath: path,
        referencePhrase: phrase,
      );

      // 4) Pitch result mavjud.
      expect(pitchResult.pitch.status, isNot(MetricStatus.notConnected));
      // 5) Pitch contour mavjud.
      expect(pitchResult.pitchContour, isNotEmpty);
      // 6) Reference mavjud bo'lsa reference contour mavjud.
      expect(
        pitchResult.referenceComparison.status,
        ReferenceComparisonStatus.available,
      );
      expect(
        pitchResult.referenceComparison.referenceContour,
        isNotEmpty,
      );
      // 8) Duration analysis ishlaydi.
      expect(durationResult.status, DurationComparisonStatus.available);
      expect(durationResult.userActiveDurationMs, isNotNull);
      expect(durationResult.referenceActiveDurationMs, isNotNull);
    });

    test(
        '7/9) "Qod qoomatis-solaah" uchun reference yo\'q -> crash '
        'bermaydi, user pitch/contour/duration baribir mavjud', () async {
      final phrase = PhraseCatalog.byId('iqomat_qad_qomatis_solah');

      final userWav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.0,
        toneHz: 200,
      );
      final path = await writeTempWav('qad_qomatis.wav', userWav);

      final pitchAnalyzer = PitchAnalyzer(
        referenceChecker: const _FakeCheckerUnavailable(),
      );
      final durationAnalyzer = DurationAnalyzer(
        referenceChecker: const _FakeCheckerUnavailable(),
      );

      // Hech qanday exception otilmasligi kerak.
      final pitchResult = await pitchAnalyzer.analyze(
        recordingPath: path,
        referencePhrase: phrase,
      );
      final durationResult = await durationAnalyzer.analyze(
        recordingPath: path,
        referencePhrase: phrase,
      );

      // 7) Reference mavjud bo'lmasa user contour baribir mavjud.
      expect(pitchResult.pitchContour, isNotEmpty);
      expect(pitchResult.pitch.status, isNot(MetricStatus.notConnected));
      expect(
        pitchResult.referenceComparison.status,
        ReferenceComparisonStatus.notAvailable,
      );
      expect(
        pitchResult.referenceComparison.message,
        'Reference audio mavjud emas — taqqoslash bajarilmadi.',
      );

      expect(durationResult.status, DurationComparisonStatus.notAvailable);
      expect(durationResult.userDurationMs, isNotNull);
      expect(durationResult.userActiveDurationMs, isNotNull);
    });

    test('10) Azon hamon buzilmagan — bir xil pipeline, boshqa jumla',
        () async {
      final phrase = PhraseCatalog.byId('azon_allohu_akbar');
      final userWav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.0,
        toneHz: 200,
      );
      final path = await writeTempWav('azon_user.wav', userWav);

      final pitchAnalyzer = PitchAnalyzer(
        referenceChecker: const _FakeCheckerUnavailable(),
      );
      final result = await pitchAnalyzer.analyze(
        recordingPath: path,
        referencePhrase: phrase,
      );

      expect(result.pitchContour, isNotEmpty);
      expect(result.pitch.status, isNot(MetricStatus.notConnected));
    });
  });
}
