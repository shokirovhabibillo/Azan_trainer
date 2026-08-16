import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/models/pitch_frame.dart';
import 'package:azon_trainer/models/reference_comparison_result.dart';
import 'package:azon_trainer/services/analysis/reference_pitch_comparator.dart';

/// Sinusoidal shaklga o'xshash, vaqt bo'ylab ko'tarilib-tushadigan
/// pitch contour yaratadi (o'zgarmas balandlik emas — Pearson
/// korrelyatsiyasi ma'noli hisoblanishi uchun).
List<PitchFrame> _arcContour({
  required double baseHz,
  double amplitudeHz = 20,
  int frameCount = 30,
  int hopMs = 64,
  double hzMultiplier = 1.0,
}) {
  final frames = <PitchFrame>[];
  for (int i = 0; i < frameCount; i++) {
    final phase = i / (frameCount - 1); // 0..1
    // Yarim sinus shaklidagi arc: boshida past, o'rtada baland, oxirida past.
    final shape = (phase * 3.14159265).abs();
    final hz = (baseHz + amplitudeHz * (1 - (shape - 1.5708).abs() / 1.5708)) *
        hzMultiplier;
    frames.add(
      PitchFrame(
        timestampMs: i * hopMs,
        frequencyHz: hz,
        voiced: true,
      ),
    );
  }
  return frames;
}

double _durationOf(List<PitchFrame> frames, int hopMs) =>
    (frames.last.timestampMs + hopMs) / 1000;

void main() {
  const comparator = ReferencePitchComparator();

  test('bir xil (identical) contourlar — matched, similarity yuqori', () {
    final contour = _arcContour(baseHz: 180);
    final duration = _durationOf(contour, 64);

    final result = comparator.compare(
      userContour: contour,
      userDurationSeconds: duration,
      userVoicedRatio: 1.0,
      referenceContour: contour,
      referenceDurationSeconds: duration,
      referenceVoicedRatio: 1.0,
    );

    expect(result.status, ReferenceComparisonStatus.available);
    expect(result.pitchAlignment, PitchAlignment.matched);
    expect(result.message, 'Pitch reference bilan yaxshi mos kelmoqda.');
    expect(result.contourSimilarity, greaterThan(0.9));
    expect(result.meanPitchDifferenceSemitones!.abs(), lessThan(0.5));
  });

  test('user pitch reference\'dan yuqori — userHigher', () {
    final reference = _arcContour(baseHz: 180);
    final duration = _durationOf(reference, 64);
    // 1.5x chastota ≈ +7 semiton (shakl bir xil qoladi, faqat daraja
    // ko'tariladi — log-scale'da additive constant, korrelyatsiya
    // o'zgarmaydi).
    final user = _arcContour(baseHz: 180, hzMultiplier: 1.5);

    final result = comparator.compare(
      userContour: user,
      userDurationSeconds: duration,
      userVoicedRatio: 1.0,
      referenceContour: reference,
      referenceDurationSeconds: duration,
      referenceVoicedRatio: 1.0,
    );

    expect(result.pitchAlignment, PitchAlignment.userHigher);
    expect(result.message, 'Pitch reference\'dan ancha yuqori.');
    expect(result.meanPitchDifferenceSemitones, greaterThan(1.0));
    // Shakl bir xil qolgani uchun similarity baribir yuqori bo'lishi kerak.
    expect(result.contourSimilarity, greaterThan(0.8));
  });

  test('user pitch reference\'dan past — userLower', () {
    final reference = _arcContour(baseHz: 180);
    final duration = _durationOf(reference, 64);
    final user = _arcContour(baseHz: 180, hzMultiplier: 0.7);

    final result = comparator.compare(
      userContour: user,
      userDurationSeconds: duration,
      userVoicedRatio: 1.0,
      referenceContour: reference,
      referenceDurationSeconds: duration,
      referenceVoicedRatio: 1.0,
    );

    expect(result.pitchAlignment, PitchAlignment.userLower);
    expect(result.message, 'Pitch reference\'dan ancha past.');
    expect(result.meanPitchDifferenceSemitones, lessThan(-1.0));
  });

  test('contour shakli mos kelmaydi — unstable', () {
    final reference = _arcContour(baseHz: 180, amplitudeHz: 40);
    final duration = _durationOf(reference, 64);

    // User contouri: teskari yo'nalishda tebranadi (boshida baland,
    // oxirida past) — reference bilan shakl jihatidan bog'liq emas.
    final user = <PitchFrame>[];
    for (int i = 0; i < 30; i++) {
      final hz = i.isEven ? 140.0 : 260.0;
      user.add(PitchFrame(timestampMs: i * 64, frequencyHz: hz, voiced: true));
    }

    final result = comparator.compare(
      userContour: user,
      userDurationSeconds: duration,
      userVoicedRatio: 1.0,
      referenceContour: reference,
      referenceDurationSeconds: duration,
      referenceVoicedRatio: 1.0,
    );

    expect(result.pitchAlignment, PitchAlignment.unstable);
    expect(result.message, 'Pitch contour beqaror.');
  });

  test('silence/unvoiced — umumiy voiced nuqta yo\'q → insufficientData', () {
    final reference = _arcContour(baseHz: 180);
    final duration = _durationOf(reference, 64);

    final silentUser = List.generate(
      30,
      (i) => PitchFrame(timestampMs: i * 64, frequencyHz: 0, voiced: false),
    );

    final result = comparator.compare(
      userContour: silentUser,
      userDurationSeconds: duration,
      userVoicedRatio: 0.0,
      referenceContour: reference,
      referenceDurationSeconds: duration,
      referenceVoicedRatio: 1.0,
    );

    expect(result.pitchAlignment, PitchAlignment.insufficientData);
    expect(result.meanPitchDifferenceSemitones, isNull);
    expect(result.contourSimilarity, isNull);
  });

  test(
      'faqat bir necha voiced freym (asosan unvoiced) → insufficientData',
      () {
    final reference = _arcContour(baseHz: 180, frameCount: 30);
    final duration = _durationOf(reference, 64);

    // 30 freymdan faqat birinchisi voiced, qolgani unvoiced — resample
    // panjarasida umumiy voiced nuqtalar minCommonPoints'dan kam bo'ladi.
    final user = <PitchFrame>[
      const PitchFrame(timestampMs: 0, frequencyHz: 180, voiced: true),
      ...List.generate(
        29,
        (i) => PitchFrame(
          timestampMs: (i + 1) * 64,
          frequencyHz: 0,
          voiced: false,
        ),
      ),
    ];

    final result = comparator.compare(
      userContour: user,
      userDurationSeconds: duration,
      userVoicedRatio: 1 / 30,
      referenceContour: reference,
      referenceDurationSeconds: duration,
      referenceVoicedRatio: 1.0,
    );

    expect(result.pitchAlignment, PitchAlignment.insufficientData);
    expect(
      result.message,
      contains('yetarli emas'),
    );
  });
}
