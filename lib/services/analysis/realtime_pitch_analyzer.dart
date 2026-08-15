import 'dart:math' as math;
import 'dart:typed_data';

import 'yin_pitch_detector.dart';

/// v1.14: bitta real-vaqt pitch o'lchovi natijasi.
class RealtimePitchSample {
  final int timestampMs;
  final double frequencyHz;
  final bool voiced;
  final double confidence;

  const RealtimePitchSample({
    required this.timestampMs,
    required this.frequencyHz,
    required this.voiced,
    required this.confidence,
  });

  static RealtimePitchSample unvoiced(int timestampMs) => RealtimePitchSample(
        timestampMs: timestampMs,
        frequencyHz: 0,
        voiced: false,
        confidence: 0,
      );
}

/// v1.14: mikrofondan kelayotgan RAW PCM16 baytlarni ketma-ket qabul
/// qilib, freym to'lgan sayin pitch hisoblaydigan, holatli (stateful)
/// controller.
///
/// MUHIM: bu klass `YinPitchDetector`ni (v1.3'da tasdiqlangan, hech
/// qanday o'zgartirilmagan) to'g'ridan-to'g'ri chaqiradi — YIN
/// algoritmining o'zi bu yerda QAYTA YOZILMAGAN. Freym o'lchami (2048),
/// RMS jimlik chegarasi (0.012) qiymatlari ham
/// `PitchContourExtractor`dagi (v1.1'dan tasdiqlangan) qiymatlar bilan
/// BIR XIL — shunda real-vaqt va yakuniy (post-hoc) tahlil bir xil
/// sezgirlikda ishlaydi.
///
/// Ishlatilishi: mikrofon oqimidan kelgan har bir bayt bo'lagini
/// `addBytes()` orqali uzatiladi; freym to'lgan sayin natija
/// `onSample` callback orqali darhol qaytariladi (kechikish — faqat
/// bitta freymning davomiyligi, ~128ms 16kHz'da).
class RealtimePitchAnalyzer {
  final YinPitchDetector _detector;
  final int frameSize;
  final int hopSize;
  final double silenceRmsThreshold;
  final int sampleRate;

  /// Hali to'liq freym bo'lmagan, navbatda turgan namunalar.
  final List<double> _pending = [];

  /// Ishlov berilgan umumiy namunalar soni — vaqt tamg'asini
  /// hisoblash uchun.
  int _samplesConsumed = 0;

  RealtimePitchAnalyzer({
    required this.sampleRate,
    YinPitchDetector? detector,
    this.frameSize = 2048,
    this.hopSize = 1024,
    this.silenceRmsThreshold = 0.012,
  }) : _detector = detector ?? const YinPitchDetector();

  /// Mikrofondan kelgan RAW PCM16 (little-endian, mono) baytlar
  /// bo'lagini qabul qiladi. Har safar yetarli namuna to'planganda,
  /// bitta yoki bir nechta [RealtimePitchSample] qaytaradi (odatda
  /// bo'sh yoki bitta — juda katta bayt bo'lagi kelsa bir nechta
  /// bo'lishi ham mumkin).
  List<RealtimePitchSample> addBytes(Uint8List bytes) {
    final results = <RealtimePitchSample>[];

    // Little-endian PCM16 baytlarni -1.0..1.0 oralig'idagi double
    // namunalarga aylantiramiz (WavDecoder ishlatgan xuddi shu
    // normalizatsiya: raw / 32768.0).
    final byteData = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2;
    for (int i = 0; i < sampleCount; i++) {
      final raw = byteData.getInt16(i * 2, Endian.little);
      _pending.add(raw / 32768.0);
    }

    while (_pending.length >= frameSize) {
      final frame = Float64List.fromList(_pending.sublist(0, frameSize));
      // Keyingi freym hopSize qadar siljiydi (overlap) — qolgan
      // namunalar keyingi freymga o'tadi.
      _pending.removeRange(0, math.min(hopSize, _pending.length));

      final timestampMs = (_samplesConsumed / sampleRate * 1000).round();
      _samplesConsumed += hopSize;

      final rms = _rms(frame);
      if (rms < silenceRmsThreshold) {
        results.add(RealtimePitchSample.unvoiced(timestampMs));
        continue;
      }

      final yin = _detector.detect(frame, sampleRate);
      results.add(
        RealtimePitchSample(
          timestampMs: timestampMs,
          frequencyHz: yin.voiced ? yin.frequencyHz : 0,
          voiced: yin.voiced,
          confidence: yin.confidence,
        ),
      );
    }

    return results;
  }

  /// Holatni tozalaydi — yangi recording sessiyasi boshlanganda
  /// chaqiriladi.
  void reset() {
    _pending.clear();
    _samplesConsumed = 0;
  }

  double _rms(Float64List frame) {
    double sum = 0;
    for (final s in frame) {
      sum += s * s;
    }
    return math.sqrt(sum / frame.length);
  }
}
