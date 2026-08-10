import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/models/duration_comparison_result.dart';
import 'package:azon_trainer/services/analysis/duration_analyzer.dart';
import 'package:azon_trainer/services/analysis/wav_decoder.dart';
import 'package:azon_trainer/services/audio/reference_audio_checker.dart';
import 'package:azon_trainer/services/audio/reference_audio_loader.dart';

import 'helpers/wav_test_helper.dart';

/// MUHIM: bu fayldagi fake checker/loader hech qanday narsani
/// assets/audio/ ichiga yozmaydi — faqat DurationAnalyzer'ning
/// konstruktor orqali almashtirilishi mumkin bo'lgan qismlarini test
/// doirasida (xotirada) almashtiradi.

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
  final phrase = PhraseCatalog.byId('azon_allohu_akbar');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('azon_trainer_dur_test_');
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

  test('1) User va reference davomiyligi bir xil -> veryClose', () async {
    final wav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: 200,
    );
    final path = await writeTempWav('same.wav', wav);

    final analyzer = DurationAnalyzer(
      referenceChecker: const _FakeCheckerAvailable(),
      referenceLoader: _FakeLoader((_) => wav),
    );
    final result = await analyzer.analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.status, DurationComparisonStatus.available);
    expect(result.feedbackType, DurationFeedbackType.veryClose);
    expect(result.feedback, 'Reference bilan davomiylik juda yaqin.');
    expect(result.durationRatio, closeTo(1.0, 0.02));
  });

  test('2) User reference\'dan sezilarli qisqaroq -> userShorter', () async {
    final userWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 0.6,
      toneHz: 200,
    );
    final refWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: 200,
    );
    final path = await writeTempWav('shorter.wav', userWav);

    final analyzer = DurationAnalyzer(
      referenceChecker: const _FakeCheckerAvailable(),
      referenceLoader: _FakeLoader((_) => refWav),
    );
    final result = await analyzer.analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.feedbackType, DurationFeedbackType.userShorter);
    expect(result.feedback, 'User phrase reference\'dan qisqaroq.');
    expect(result.durationRatio, lessThan(DurationAnalyzer.closeRatioLowerBound));
  });

  test('3) User reference\'dan sezilarli uzunroq -> userLonger', () async {
    final userWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 2.4,
      toneHz: 200,
    );
    final refWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: 200,
    );
    final path = await writeTempWav('longer.wav', userWav);

    final analyzer = DurationAnalyzer(
      referenceChecker: const _FakeCheckerAvailable(),
      referenceLoader: _FakeLoader((_) => refWav),
    );
    final result = await analyzer.analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.feedbackType, DurationFeedbackType.userLonger);
    expect(result.feedback, 'User phrase reference\'dan uzunroq.');
    expect(result.durationRatio, greaterThan(DurationAnalyzer.closeRatioUpperBound));
  });

  test('4) Reference mavjud emas -> notAvailable, fake taqqoslash yo\'q',
      () async {
    final wav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.0,
      toneHz: 200,
    );
    final path = await writeTempWav('no_ref.wav', wav);

    final analyzer = DurationAnalyzer(
      referenceChecker: const _FakeCheckerUnavailable(),
    );
    final result = await analyzer.analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.status, DurationComparisonStatus.notAvailable);
    expect(result.available, false);
    expect(
      result.feedback,
      'Reference audio mavjud emas — duration comparison bajarilmadi.',
    );
    expect(result.referenceDurationMs, isNull);
    expect(result.durationRatio, isNull);
    // User tomonidagi qiymatlar baribir saqlanadi.
    expect(result.userDurationMs, isNotNull);
  });

  test('5) Leading/trailing silence — faol davomiylik umumiy fayldan kichik',
      () async {
    // Boshida va oxirida ~0.4s jimlik, o'rtada ~1.0s tovush.
    final silence = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 0.4,
      toneHz: null,
    );
    final tone = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.0,
      toneHz: 200,
    );
    final combined = _concatWavPcm(silence, tone, silence, sampleRate: 16000);
    final path = await writeTempWav('padded.wav', combined);

    final refWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.0,
      toneHz: 200,
    );

    final analyzer = DurationAnalyzer(
      referenceChecker: const _FakeCheckerAvailable(),
      referenceLoader: _FakeLoader((_) => refWav),
    );
    final result = await analyzer.analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.status, DurationComparisonStatus.available);
    // Umumiy fayl uzunligi ~1.8s.
    expect(result.userDurationMs, greaterThan(1700));
    // MUHIM tekshiruv: faol (voiced) qism umumiy fayl uzunligidan
    // SEZILARLI kichik bo'lishi kerak — bu boshi/oxiridagi jimlik
    // to'g'ri kesib tashlanganini isbotlaydi (talab #3). Frame-oynasi
    // chegara effektlari tufayli aniq qiymatni emas, faqat nisbatni
    // tekshiramiz (windowing artefaktlariga chidamli bo'lishi uchun).
    expect(
      result.userActiveDurationMs! < result.userDurationMs! * 0.75,
      isTrue,
      reason: 'Faol davomiylik (${result.userActiveDurationMs}ms) umumiy '
          'davomiylikning (${result.userDurationMs}ms) 75%idan kichik '
          'bo\'lishi kerak edi — jimlik to\'g\'ri kesilmagan bo\'lishi mumkin',
    );
    // Faol qism nolga teng emas (ovoz haqiqatan aniqlangan).
    expect(result.userActiveDurationMs, greaterThan(0));
    expect(result.feedbackType, isNot(DurationFeedbackType.activeTooShort));
  });

  test('6) Juda qisqa audio -> activeTooShort (yoki notAvailable, lekin fake emas)',
      () async {
    final userWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 0.15,
      toneHz: 200,
    );
    final refWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: 200,
    );
    final path = await writeTempWav('tooshort.wav', userWav);

    final analyzer = DurationAnalyzer(
      referenceChecker: const _FakeCheckerAvailable(),
      referenceLoader: _FakeLoader((_) => refWav),
    );
    final result = await analyzer.analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.status, DurationComparisonStatus.available);
    expect(result.feedbackType, DurationFeedbackType.activeTooShort);
    expect(result.feedback, 'Faol ovozli qism juda qisqa.');
  });

  test('7) Faqat silence -> activeTooShort (faol qism 0)', () async {
    final userWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.2,
      toneHz: null,
    );
    final refWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: 200,
    );
    final path = await writeTempWav('silence.wav', userWav);

    final analyzer = DurationAnalyzer(
      referenceChecker: const _FakeCheckerAvailable(),
      referenceLoader: _FakeLoader((_) => refWav),
    );
    final result = await analyzer.analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.feedbackType, DurationFeedbackType.activeTooShort);
    expect(result.userActiveDurationMs, 0);
    expect(result.userVoicedRatio, 0);
  });

  test('8) Normal voiced audio — asosiy statistikalar to\'g\'ri hisoblanadi',
      () async {
    final userWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: 220,
    );
    final refWav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: 220,
    );
    final path = await writeTempWav('normal.wav', userWav);

    final analyzer = DurationAnalyzer(
      referenceChecker: const _FakeCheckerAvailable(),
      referenceLoader: _FakeLoader((_) => refWav),
    );
    final result = await analyzer.analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.status, DurationComparisonStatus.available);
    expect(result.userDurationMs, closeTo(1500, 5));
    expect(result.referenceDurationMs, closeTo(1500, 5));
    expect(result.userVoicedRatio, greaterThan(0.8));
    expect(result.referenceVoicedRatio, greaterThan(0.8));
    expect(result.durationDifferenceMs, isNotNull);
    expect(result.durationRatio, isNotNull);
  });
}

/// Bir nechta sof-PCM WAV baytlarini bitta WAV fayl sifatida birlashtiradi
/// (RIFF/fmt headerini bittasidan oladi, data qismlarini ketma-ket qo'shadi).
/// Faqat testlar uchun — ilova kodida ishlatilmaydi.
Uint8List _concatWavPcm(Uint8List a, Uint8List b, Uint8List c,
    {required int sampleRate}) {
  Uint8List pcmOf(Uint8List wav) => wav.sublist(44);
  final pcmA = pcmOf(a);
  final pcmB = pcmOf(b);
  final pcmC = pcmOf(c);
  final totalPcmLength = pcmA.length + pcmB.length + pcmC.length;

  final buffer = ByteData(44 + totalPcmLength);
  void writeString(int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  buffer.setUint32(4, 36 + totalPcmLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);
  buffer.setUint16(22, 1, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little);
  buffer.setUint16(32, 2, Endian.little);
  buffer.setUint16(34, 16, Endian.little);
  writeString(36, 'data');
  buffer.setUint32(40, totalPcmLength, Endian.little);

  final out = buffer.buffer.asUint8List();
  out.setRange(44, 44 + pcmA.length, pcmA);
  out.setRange(44 + pcmA.length, 44 + pcmA.length + pcmB.length, pcmB);
  out.setRange(
    44 + pcmA.length + pcmB.length,
    44 + totalPcmLength,
    pcmC,
  );
  return out;
}
