import 'dart:math' as math;
import 'dart:typed_data';

/// Bitta freym uchun YIN algoritmi natijasi.
class YinResult {
  final double frequencyHz;
  final bool voiced;

  /// YIN "aperiodicity" qiymati (0 ga yaqin — toza ohang, 1 ga yaqin —
  /// shovqin). Kelajakda pitch barqarorligi/ishonchlilik tahlili uchun
  /// foydali bo'lishi mumkin.
  final double confidence;

  const YinResult({
    required this.frequencyHz,
    required this.voiced,
    required this.confidence,
  });

  static const unvoiced = YinResult(
    frequencyHz: 0,
    voiced: false,
    confidence: 0,
  );
}

/// YIN algoritmi asosida asosiy chastota (F0/pitch) aniqlash.
///
/// Manba: de Cheveigné & Kawahara, "YIN, a fundamental frequency
/// estimator for speech and music" (2002). Sof Dart implementatsiyasi,
/// hech qanday tashqi native kutubxona yoki platform kanaliga bog'liq
/// emas — shuning uchun Android/iOS/boshqa platformalarda bir xil
/// ishlaydi.
class YinPitchDetector {
  /// Inson ovozi (va azon/iqomat o'qish) uchun odatiy F0 diapazoni.
  final double minFrequencyHz;
  final double maxFrequencyHz;

  /// Aperiodicity threshold — kichikroq qiymat = qattiqroq voiced talabi.
  final double threshold;

  const YinPitchDetector({
    this.minFrequencyHz = 70,
    this.maxFrequencyHz = 500,
    this.threshold = 0.15,
  });

  /// [frame] — bitta tahlil oynasi (masalan, 2048 namuna).
  /// [sampleRate] — namunalash chastotasi (Hz).
  YinResult detect(Float64List frame, int sampleRate) {
    final maxLag = math.min(
      frame.length - 1,
      (sampleRate / minFrequencyHz).floor(),
    );
    final minLag = math.max(2, (sampleRate / maxFrequencyHz).floor());

    if (maxLag <= minLag) return YinResult.unvoiced;

    // 1) Difference function d(tau)
    final diff = Float64List(maxLag + 1);
    for (int tau = minLag; tau <= maxLag; tau++) {
      double sum = 0;
      final limit = frame.length - tau;
      for (int i = 0; i < limit; i++) {
        final delta = frame[i] - frame[i + tau];
        sum += delta * delta;
      }
      diff[tau] = sum;
    }

    // 2) Cumulative mean normalized difference function d'(tau)
    final cmnd = Float64List(maxLag + 1);
    cmnd[0] = 1.0;
    double runningSum = 0;
    for (int tau = 1; tau <= maxLag; tau++) {
      runningSum += diff[tau];
      cmnd[tau] = runningSum == 0 ? 1.0 : diff[tau] * tau / runningSum;
    }

    // 3) Absolute threshold — birinchi lokal minimumni topamiz.
    int? chosenTau;
    for (int tau = minLag; tau <= maxLag; tau++) {
      if (cmnd[tau] < threshold) {
        // Lokal minimum ekanini tekshiramiz.
        while (tau + 1 <= maxLag && cmnd[tau + 1] < cmnd[tau]) {
          tau++;
        }
        chosenTau = tau;
        break;
      }
    }

    if (chosenTau == null) {
      // Threshold'dan pastroq nuqta topilmadi — unvoiced deb hisoblaymiz.
      return YinResult.unvoiced;
    }

    // 4) Parabolik interpolyatsiya — aniqlikni oshirish uchun.
    final betterTau = _parabolicInterpolation(cmnd, chosenTau, maxLag);
    if (betterTau <= 0) return YinResult.unvoiced;

    final frequency = sampleRate / betterTau;
    if (frequency < minFrequencyHz || frequency > maxFrequencyHz) {
      return YinResult.unvoiced;
    }

    return YinResult(
      frequencyHz: frequency,
      voiced: true,
      confidence: (1.0 - cmnd[chosenTau].clamp(0.0, 1.0)).toDouble(),
    );
  }

  double _parabolicInterpolation(Float64List cmnd, int tau, int maxLag) {
    if (tau <= 0 || tau >= maxLag) return tau.toDouble();
    final x0 = cmnd[tau - 1];
    final x1 = cmnd[tau];
    final x2 = cmnd[tau + 1];
    final denom = (x0 + x2 - 2 * x1);
    if (denom == 0) return tau.toDouble();
    final delta = (x0 - x2) / (2 * denom);
    return tau + delta;
  }
}
