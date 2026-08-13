import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/models/maqam.dart';
import 'package:azon_trainer/models/reference_comparison_result.dart';
import 'package:azon_trainer/services/analysis/pitch_analyzer.dart';
import 'package:azon_trainer/services/analysis/pitch_contour_extractor.dart';
import 'package:azon_trainer/services/analysis/wav_decoder.dart';
import 'package:azon_trainer/services/audio/reference_audio_checker.dart';
import 'package:azon_trainer/services/audio/reference_audio_loader.dart';

import 'helpers/wav_test_helper.dart';

/// MUHIM: bu fayldagi "fake" checker/loader'lar hech qanday narsani
/// assets/audio/ ichiga yozmaydi va app bundle'ga tegishli emas — ular
/// faqat PitchAnalyzer'ning konstruktor orqali dependency-injection
/// qila oladigan qismlarini (ReferenceAudioChecker/ReferenceAudioLoader)
/// test doirasida almashtiradi, xotirada. Bu "reference mavjud" yo'lini
/// haqiqiy fayl qo'shmasdan sinash imkonini beradi.

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

/// Berilgan bayt massivini "asset"dan o'qilgandek qaytaradi.
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
  final phrase = PhraseCatalog.byId('azon_allohu_akbar');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('azon_trainer_v13_test_');
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

  group('Reference mavjudlik holatlari', () {
    test('reference mavjud emas → notAvailable, fake taqqoslash yo\'q',
        () async {
      final userWav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.0,
        toneHz: 200,
      );
      final path = await writeTempWav('user_no_ref.wav', userWav);

      final analyzer = PitchAnalyzer(
        referenceChecker: const _FakeCheckerUnavailable(),
      );
      final result = await analyzer.analyze(
        recordingPath: path,
        referencePhrase: phrase,
      );

      expect(
        result.referenceComparison.status,
        ReferenceComparisonStatus.notAvailable,
      );
      expect(result.referenceComparison.referenceContour, isEmpty);
    });

    test('reference mavjud + WAV to\'g\'ri → available, taqqoslash bajariladi',
        () async {
      final toneWav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.2,
        toneHz: 200,
      );
      final userWav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.2,
        toneHz: 200,
      );
      final path = await writeTempWav('user_with_ref.wav', userWav);

      final analyzer = PitchAnalyzer(
        referenceChecker: const _FakeCheckerAvailable(),
        referenceLoader: _FakeLoader((_) => toneWav),
      );
      final result = await analyzer.analyze(
        recordingPath: path,
        referencePhrase: phrase,
      );

      // Bir xil ohangdagi user va reference — taqqoslash "available"
      // bo'lishi va "mos keladi" xabarini berishi kerak.
      expect(
        result.referenceComparison.status,
        ReferenceComparisonStatus.available,
      );
      expect(
        result.referenceComparison.pitchAlignment,
        PitchAlignment.matched,
      );
      expect(
        result.referenceComparison.message,
        'Pitch reference bilan yaxshi mos kelmoqda.',
      );
      expect(result.referenceComparison.referenceContour, isNotEmpty);
      expect(
        result.referenceComparison.referenceDurationSeconds,
        closeTo(1.2, 0.05),
      );
    });

    test('noto\'g\'ri/buzilgan asset (WAV emas) → decodeError, fake emas',
        () async {
      final userWav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.0,
        toneHz: 200,
      );
      final path = await writeTempWav('user_bad_ref.wav', userWav);

      final garbageBytes = Uint8List.fromList(
        List.generate(20, (i) => i), // WAV emas — RIFF header yo'q
      );

      final analyzer = PitchAnalyzer(
        referenceChecker: const _FakeCheckerAvailable(),
        referenceLoader: _FakeLoader((_) => garbageBytes),
      );
      final result = await analyzer.analyze(
        recordingPath: path,
        referencePhrase: phrase,
      );

      expect(
        result.referenceComparison.status,
        ReferenceComparisonStatus.decodeError,
      );
      expect(result.referenceComparison.message, contains('o\'qib bo\'lmadi'));
      expect(result.referenceComparison.meanPitchDifferenceSemitones, isNull);
    });
  });

  group('Reference WAV decode va pitch extraction (to\'g\'ridan-to\'g\'ri)', () {
    test('WavDecoder reference baytlarini to\'g\'ri dekodlaydi', () {
      final wav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 0.8,
        toneHz: 300,
      );
      final decoded = const WavDecoder().decodeBytes(wav);

      expect(decoded.sampleRate, 16000);
      expect(decoded.durationSeconds, closeTo(0.8, 0.01));
      expect(decoded.samples.length, greaterThan(0));
    });

    test('PitchContourExtractor reference audiodan F0 contour chiqaradi',
        () {
      final wav = buildTestWav(
        sampleRate: 16000,
        durationSeconds: 1.0,
        toneHz: 250,
      );
      final decoded = const WavDecoder().decodeBytes(wav);
      final contour = const PitchContourExtractor().extract(decoded);

      final voiced = contour.where((f) => f.voiced).toList();
      expect(voiced, isNotEmpty);
      final freqs = voiced.map((f) => f.frequencyHz).toList();
      final avg = freqs.reduce((a, b) => a + b) / freqs.length;
      expect(avg, closeTo(250, 20));
    });
  });

  group('Bomdod jumla takrorlanishi', () {
    test(
        'azonSequence(isBomdod: true) — qo\'shimcha jumla aynan 1 marta, '
        'repeatCount=2 bilan qo\'shiladi', () {
      final sequence = PhraseCatalog.azonSequence(isBomdod: true);

      final bomdodEntries = sequence.where(
        (p) => p.id == 'bomdod_assolatu_khoyrum_minan_navm',
      );
      expect(bomdodEntries.length, 1);
      expect(bomdodEntries.first.repeatCount, 2);

      // "Hayya alal-falah"dan darhol keyin joylashgan bo'lishi kerak.
      final falahIndex = sequence.indexWhere(
        (p) => p.id == 'azon_hayya_alal_falah',
      );
      final bomdodIndex = sequence.indexWhere(
        (p) => p.id == 'bomdod_assolatu_khoyrum_minan_navm',
      );
      expect(bomdodIndex, falahIndex + 1);
    });

    test('azonSequence(isBomdod: false) — bomdod qo\'shimchasi yo\'q', () {
      final sequence = PhraseCatalog.azonSequence(isBomdod: false);
      final bomdodEntries = sequence.where(
        (p) => p.id == 'bomdod_assolatu_khoyrum_minan_navm',
      );
      expect(bomdodEntries, isEmpty);
    });
  });

  group('Yakuniy takbir (v1.5 fix) — "Laa ilaaha illalloh"dan oldin', () {
    test('oddiy azonda yakuniy takbir mavjud, repeatCount=2, va '
        '"Laa ilaaha illalloh"dan darhol oldin turadi', () {
      final sequence = PhraseCatalog.azonSequence(isBomdod: false);

      final closingEntries = sequence.where(
        (p) => p.id == 'azon_allohu_akbar_closing',
      );
      expect(closingEntries.length, 1);
      expect(closingEntries.first.repeatCount, 2);

      final closingIndex = sequence.indexWhere(
        (p) => p.id == 'azon_allohu_akbar_closing',
      );
      final laaIlaahaIndex = sequence.indexWhere(
        (p) => p.id == 'azon_laa_ilaaha_illalloh',
      );
      expect(laaIlaahaIndex, closingIndex + 1);
    });

    test('Bomdod azonida yakuniy takbir Bomdod qo\'shimchasidan keyin, '
        '"Laa ilaaha illalloh"dan oldin turadi', () {
      final sequence = PhraseCatalog.azonSequence(isBomdod: true);

      final bomdodIndex = sequence.indexWhere(
        (p) => p.id == 'bomdod_assolatu_khoyrum_minan_navm',
      );
      final closingIndex = sequence.indexWhere(
        (p) => p.id == 'azon_allohu_akbar_closing',
      );
      final laaIlaahaIndex = sequence.indexWhere(
        (p) => p.id == 'azon_laa_ilaaha_illalloh',
      );

      expect(closingIndex, bomdodIndex + 1);
      expect(laaIlaahaIndex, closingIndex + 1);
    });
  });

  group('Maqom metadata', () {
    test(
        'v1.9: Azon jumlalari uchun maqam Bayati (haqiqiy reference '
        'audio qo\'shilgach tasdiqlangan)', () {
      for (final p in PhraseCatalog.azon) {
        expect(
          p.maqam.label,
          'Bayati',
          reason: '${p.id} uchun maqom Bayati bo\'lishi kerak edi',
        );
      }
    });

    test(
        'Reference audio hali qo\'shilmagan jumlalar (Bomdod qo\'shimchasi, '
        'Iqomat) uchun maqam hamon unknown — taxmin qilinmagan', () {
      final noAudioYet = [
        PhraseCatalog.bomdodExtra,
        ...PhraseCatalog.iqomat,
      ];
      for (final p in noAudioYet) {
        expect(
          p.maqam.label,
          'unknown',
          reason:
              '${p.id} uchun maqom hali tasdiqlanmagan bo\'lishi kerak',
        );
      }
    });
  });
}
