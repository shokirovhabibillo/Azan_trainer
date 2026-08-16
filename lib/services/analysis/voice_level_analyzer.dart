import 'dart:math' as math;
import 'dart:typed_data';

/// v1.14: real-vaqt ovoz darajasi (volume) natijasi.
///
/// MUHIM: bu — PITCH emas. Pitch (ohang balandligi/nota) va Volume
/// (ovoz kuchi) FIZIK jihatdan mutlaqo boshqa-boshqa kattaliklar —
/// past ovozda ham baland nota, baland ovozda ham past nota
/// aytilishi mumkin. Shuning uchun bu klass `RealtimePitchAnalyzer`
/// bilan bog'liq emas, mustaqil ishlaydi.
class VoiceLevelSample {
  /// 0.0 (jimlik) .. 1.0 (juda baland) oralig'idagi normallashtirilgan
  /// daraja.
  final double level;

  const VoiceLevelSample(this.level);

  bool get isTooQuiet => level < 0.08;
  bool get isTooLoud => level > 0.85;
  bool get isNormal => !isTooQuiet && !isTooLoud;
}

/// v1.14: RAW PCM16 bayt bo'laklaridan RMS asosida ovoz darajasini
/// hisoblaydi. Sof matematik/statistik hisoblash — hech qanday pitch
/// yoki tovush balandligi bilan bog'liq emas.
class VoiceLevelAnalyzer {
  /// RMS qiymatini 0..1 darajasiga normallashtirish uchun maksimal
  /// kutilgan RMS (odatiy gapirish balandligida taxminiy chegara).
  /// Bu qiymatdan yuqori RMS 1.0 (max) ga "clamp" qilinadi.
  static const double _maxExpectedRms = 0.35;

  VoiceLevelSample analyze(Uint8List bytes) {
    if (bytes.isEmpty) return const VoiceLevelSample(0);

    final byteData = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return const VoiceLevelSample(0);

    double sumSquares = 0;
    for (int i = 0; i < sampleCount; i++) {
      final raw = byteData.getInt16(i * 2, Endian.little);
      final normalized = raw / 32768.0;
      sumSquares += normalized * normalized;
    }
    final rms = math.sqrt(sumSquares / sampleCount);

    double level = rms / _maxExpectedRms;
    if (level < 0) level = 0;
    if (level > 1) level = 1;
    return VoiceLevelSample(level);
  }
}
