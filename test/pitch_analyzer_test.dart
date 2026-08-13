import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/data/phrase_catalog.dart';
import 'package:azon_trainer/models/analysis_result.dart';
import 'package:azon_trainer/models/reference_comparison_result.dart';
import 'package:azon_trainer/services/analysis/pitch_analyzer.dart';

import 'helpers/wav_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('azon_trainer_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> writeWav(String name, List<int> bytes) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  final phrase = PhraseCatalog.byId('azon_allohu_akbar');

  // v1.9: Azonning barcha 7 jumlasi endi HAQIQIY reference audioga ega
  // (Bayati maqomida). Shu sababli "reference mavjud emas" holatini
  // sinash uchun endi shu jumla ishlatilmaydi — uning o'rniga hali
  // reference audiosi yo'q bo'lgan Iqomat jumlasi ishlatiladi.
  final phraseWithoutReference =
      PhraseCatalog.byId('iqomat_ashhadu_laa_ilaaha');

  test('juda qisqa recording (< 0.3s) → "Ovoz juda qisqa"', () async {
    final wav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 0.1,
      toneHz: 200,
    );
    final path = await writeWav('short.wav', wav);

    final result = await PitchAnalyzer().analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.pitch.status, MetricStatus.needsWork);
    expect(result.pitch.note, contains('Ovoz juda qisqa'));
    // Juda qisqa recordingda reference tekshiruvi umuman
    // bajarilmaydi (PitchAnalyzer._shortRecordingResult har doim
    // notAvailable qaytaradi) — reference fayl mavjud yoki yo'qligidan
    // qat'i nazar.
    expect(
      result.referenceComparison.status,
      ReferenceComparisonStatus.notAvailable,
    );
  });

  test('to\'liq jimlik (silence) → "Ovoz aniqlanmadi"', () async {
    final wav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: null,
    );
    final path = await writeWav('silence.wav', wav);

    final result = await PitchAnalyzer().analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.pitch.status, MetricStatus.needsWork);
    expect(result.pitch.note, 'Ovoz aniqlanmadi');
    expect(result.voicedRatio, 0.0);
  });

  test('normal ovozli tone (220 Hz) → pitch aniqlanadi, range mos', () async {
    final wav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.5,
      toneHz: 220,
    );
    final path = await writeWav('tone.wav', wav);

    final result = await PitchAnalyzer().analyze(
      recordingPath: path,
      referencePhrase: phrase,
    );

    expect(result.pitch.status, MetricStatus.good);
    expect(result.pitchMinHz, isNotNull);
    expect(result.pitchMaxHz, isNotNull);
    // YIN aniqligi freym chegaralarida ozgina xato berishi mumkin,
    // shuning uchun kengroq tolerantlik bilan tekshiramiz.
    expect(result.pitchMinHz, greaterThan(190));
    expect(result.pitchMaxHz, lessThan(250));
  });

  test('reference audio mavjud emas → notAvailable, fake taqqoslash yo\'q',
      () async {
    final wav = buildTestWav(
      sampleRate: 16000,
      durationSeconds: 1.0,
      toneHz: 200,
    );
    final path = await writeWav('no_reference.wav', wav);

    final result = await PitchAnalyzer().analyze(
      recordingPath: path,
      // iqomat_ashhadu_laa_ilaaha.wav — assets ichida hali yo'q.
      referencePhrase: phraseWithoutReference,
    );

    expect(
      result.referenceComparison.status,
      ReferenceComparisonStatus.notAvailable,
    );
    expect(
      result.referenceComparison.message,
      'Reference audio mavjud emas — taqqoslash bajarilmadi.',
    );
    expect(result.referenceComparison.contourSimilarity, isNull);
    expect(result.referenceComparison.meanPitchDifferenceSemitones, isNull);
  });

  test('audio fayl umuman topilmasa → xato natijasi (fake emas)', () async {
    final result = await PitchAnalyzer().analyze(
      recordingPath: '${tempDir.path}/does_not_exist.wav',
      referencePhrase: phrase,
    );

    expect(result.pitch.status, MetricStatus.needsWork);
    expect(result.pitch.note, contains('Audio fayl'));
  });
}
