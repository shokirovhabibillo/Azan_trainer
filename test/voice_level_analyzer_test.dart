import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/services/analysis/voice_level_analyzer.dart';

void main() {
  Uint8List generateTonePcm16({
    required int sampleRate,
    required double durationSeconds,
    required double toneHz,
    double amplitude = 0.5,
  }) {
    final sampleCount = (sampleRate * durationSeconds).round();
    final bytes = ByteData(sampleCount * 2);
    for (int i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final value = amplitude * math.sin(2 * math.pi * toneHz * t) * 32767;
      bytes.setInt16(i * 2, value.round(), Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  group('VoiceLevelAnalyzer', () {
    final analyzer = VoiceLevelAnalyzer();

    test('jimlik (bo\'sh baytlar) uchun level = 0, isTooQuiet = true', () {
      final silence = Uint8List(16000 * 2);
      final sample = analyzer.analyze(silence);

      expect(sample.level, 0);
      expect(sample.isTooQuiet, isTrue);
      expect(sample.isNormal, isFalse);
    });

    test('past amplitudali signal uchun isTooQuiet = true', () {
      final quiet = generateTonePcm16(
        sampleRate: 16000,
        durationSeconds: 0.1,
        toneHz: 200,
        amplitude: 0.01,
      );
      final sample = analyzer.analyze(quiet);

      expect(sample.isTooQuiet, isTrue);
    });

    test('o\'rtacha amplitudali signal uchun isNormal = true', () {
      final normal = generateTonePcm16(
        sampleRate: 16000,
        durationSeconds: 0.1,
        toneHz: 200,
        amplitude: 0.2,
      );
      final sample = analyzer.analyze(normal);

      expect(sample.isNormal, isTrue);
      expect(sample.level, greaterThan(0));
      expect(sample.level, lessThanOrEqualTo(1.0));
    });

    test(
        'juda baland amplitudali (clipping chegarasidagi) signal uchun '
        'isTooLoud = true', () {
      final loud = generateTonePcm16(
        sampleRate: 16000,
        durationSeconds: 0.1,
        toneHz: 200,
        amplitude: 0.95,
      );
      final sample = analyzer.analyze(loud);

      expect(sample.isTooLoud, isTrue);
    });

    test('level har doim 0..1 oralig\'ida (clamp qilingan)', () {
      final veryLoud = generateTonePcm16(
        sampleRate: 16000,
        durationSeconds: 0.1,
        toneHz: 200,
        amplitude: 1.0,
      );
      final sample = analyzer.analyze(veryLoud);

      expect(sample.level, greaterThanOrEqualTo(0.0));
      expect(sample.level, lessThanOrEqualTo(1.0));
    });

    test('bo\'sh bayt massivi uchun xato bermaydi', () {
      final sample = analyzer.analyze(Uint8List(0));
      expect(sample.level, 0);
    });
  });
}
