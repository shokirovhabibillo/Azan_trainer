import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/services/analysis/realtime_pitch_analyzer.dart';

/// v1.14: `RealtimePitchAnalyzer` — sof Dart, platformaga bog'liq
/// emas, to'liq unit-test qilinadigan qism.
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
      final value =
          amplitude * math.sin(2 * math.pi * toneHz * t) * 32767;
      bytes.setInt16(i * 2, value.round(), Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  Uint8List generateSilencePcm16({
    required int sampleRate,
    required double durationSeconds,
  }) {
    final sampleCount = (sampleRate * durationSeconds).round();
    return Uint8List(sampleCount * 2); // barcha baytlar 0 — jimlik
  }

  group('RealtimePitchAnalyzer — jimlik', () {
    test('faqat jimlik baytlari kelsa, barcha natijalar unvoiced', () {
      final analyzer = RealtimePitchAnalyzer(sampleRate: 16000);
      final silence = generateSilencePcm16(
        sampleRate: 16000,
        durationSeconds: 1.0,
      );

      final results = analyzer.addBytes(silence);

      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.voiced, isFalse);
        expect(r.frequencyHz, 0);
      }
    });
  });

  group('RealtimePitchAnalyzer — haqiqiy voiced audio', () {
    test('barqaror 200Hz ohang uchun voiced natijalar, chastota to\'g\'ri',
        () {
      final analyzer = RealtimePitchAnalyzer(sampleRate: 16000);
      final tone = generateTonePcm16(
        sampleRate: 16000,
        durationSeconds: 1.0,
        toneHz: 200,
      );

      final results = analyzer.addBytes(tone);

      expect(results, isNotEmpty);
      final voicedResults = results.where((r) => r.voiced).toList();
      expect(voicedResults, isNotEmpty);
      for (final r in voicedResults) {
        expect(r.frequencyHz, closeTo(200, 5));
      }
    });

    test('freym-freym kelganda ham (kichik bo\'laklarda) natija bir xil',
        () {
      final analyzerWhole = RealtimePitchAnalyzer(sampleRate: 16000);
      final analyzerChunked = RealtimePitchAnalyzer(sampleRate: 16000);
      final tone = generateTonePcm16(
        sampleRate: 16000,
        durationSeconds: 1.0,
        toneHz: 200,
      );

      final wholeResults = analyzerWhole.addBytes(tone);

      final chunkedResults = <RealtimePitchSample>[];
      const chunkSize = 512; // baytlarda, kichik bo'laklar
      for (int i = 0; i < tone.length; i += chunkSize) {
        final end = math.min(i + chunkSize, tone.length);
        chunkedResults.addAll(
          analyzerChunked.addBytes(tone.sublist(i, end)),
        );
      }

      expect(chunkedResults.length, wholeResults.length);
    });
  });

  group('RealtimePitchAnalyzer — past ovoz (low volume)', () {
    test('juda past amplitudali signal unvoiced deb hisoblanadi', () {
      final analyzer = RealtimePitchAnalyzer(sampleRate: 16000);
      final quietTone = generateTonePcm16(
        sampleRate: 16000,
        durationSeconds: 1.0,
        toneHz: 200,
        amplitude: 0.001, // silenceRmsThreshold (0.012) dan past
      );

      final results = analyzer.addBytes(quietTone);

      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.voiced, isFalse);
      }
    });
  });

  group('RealtimePitchAnalyzer — beqaror pitch', () {
    test('shovqin (random) signal ko\'pincha unvoiced yoki beqaror natija '
        'beradi (voiced bo\'lsa ham chastota tasodifiy)', () {
      final analyzer = RealtimePitchAnalyzer(sampleRate: 16000);
      final random = math.Random(42);
      const sampleCount = 16000; // 1 soniya
      final bytes = ByteData(sampleCount * 2);
      for (int i = 0; i < sampleCount; i++) {
        final value = (random.nextDouble() * 2 - 1) * 0.5 * 32767;
        bytes.setInt16(i * 2, value.round(), Endian.little);
      }
      final noise = bytes.buffer.asUint8List();

      final results = analyzer.addBytes(noise);

      // Shovqin uchun YIN odatda voiced deb hisoblamaydi yoki juda
      // beqaror natija beradi — muhimi, dastur ishlab, xato
      // bermasligi (crash qilmasligi).
      expect(results, isNotEmpty);
    });
  });

  group('RealtimePitchAnalyzer — reset', () {
    test('reset() chaqirilgach, vaqt tamg\'asi 0dan boshlanadi', () {
      final analyzer = RealtimePitchAnalyzer(sampleRate: 16000);
      final tone = generateTonePcm16(
        sampleRate: 16000,
        durationSeconds: 0.5,
        toneHz: 200,
      );

      analyzer.addBytes(tone);
      analyzer.reset();

      final resultsAfterReset = analyzer.addBytes(tone);
      expect(resultsAfterReset.first.timestampMs, 0);
    });
  });
}
