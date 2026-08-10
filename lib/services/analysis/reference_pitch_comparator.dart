import 'dart:math' as math;

import '../../models/pitch_frame.dart';
import '../../models/reference_comparison_result.dart';

/// Ikki pitch contourni (reference va user) vaqt bo'yicha normalize
/// qilib solishtiradi.
///
/// FORMULA (qadam-baqadam):
///
/// 1) Vaqtni normalize qilish: har bir contour o'zining umumiy
///    davomiyligiga bo'linadi, natijada har ikkala contour ham 0..1
///    oralig'ida ifodalanadi (recording davomiyliklari har xil bo'lsa
///    ham solishtirish mumkin bo'ladi).
///
/// 2) Bir xil tekis panjaraga (`_gridPoints` ta nuqta, 0..1) resample
///    qilinadi: har nuqta uchun eng yaqin freym olinadi (nearest
///    neighbor). Freym unvoiced bo'lsa, shu nuqta "unvoiced" deb
///    belgilanadi.
///
/// 3) Faqat ikkalasi ham voiced bo'lgan umumiy nuqtalar tanlanadi.
///    Bunday nuqta yetarli (>= [_minCommonPoints]) bo'lmasa,
///    [PitchAlignment.insufficientData] qaytariladi.
///
/// 4) Semitone farqi har nuqtada: 12 * log2(userHz / refHz).
///    O'rtachasi — meanPitchDifferenceSemitones.
///
/// 5) Contour similarity — Pearson korrelyatsiya koeffitsienti,
///    log2(Hz) qatorlari ustida (mutlaq balandlikdan mustaqil, faqat
///    "shakl" — ko'tarilish/tushish naqshi — solishtiriladi):
///
///      r = cov(x, y) / (std(x) * std(y))
///
///    0..1 oralig'iga qisiladi (manfiy korrelyatsiya 0 sifatida
///    ko'rsatiladi, chunki manfiy bog'liqlik "o'xshash emas" degani).
///    Chegaraviy holat: ikkala qator ham mutlaqo tekis (o'zgarmas
///    balandlik) bo'lsa, similarity=1 deb olinadi (daraja farqi
///    alohida meanPitchDifferenceSemitones orqali hisobga olinadi);
///    faqat bittasi tekis bo'lsa, similarity=0.
///
/// 6) Yagona feedback xabari ustuvorlik tartibida tanlanadi:
///    similarity past → "beqaror"; aks holda o'rtacha semitone farqiga
///    qarab "yuqori" / "past" / "mos keladi".
class ReferencePitchComparator {
  /// Vaqt bo'yicha resample qilinadigan nuqtalar soni.
  static const int _gridPoints = 60;

  /// Ishonchli statistika uchun kerak bo'lgan minimal umumiy voiced
  /// nuqtalar soni.
  static const int _minCommonPoints = 6;

  /// Shu semitonedan kichik o'rtacha farq — "mos keladi" deb hisoblanadi.
  static const double _matchedThresholdSemitones = 1.0;

  /// Shu qiymatdan past contour similarity — "beqaror" deb hisoblanadi
  /// (mean farq qanchalik kichik bo'lishidan qat'i nazar).
  static const double _unstableSimilarityThreshold = 0.35;

  const ReferencePitchComparator();

  ReferenceComparisonResult compare({
    required List<PitchFrame> userContour,
    required double userDurationSeconds,
    required double userVoicedRatio,
    required List<PitchFrame> referenceContour,
    required double referenceDurationSeconds,
    required double referenceVoicedRatio,
  }) {
    final userGrid = _resampleToGrid(userContour, userDurationSeconds);
    final refGrid = _resampleToGrid(referenceContour, referenceDurationSeconds);

    final userLogHz = <double>[];
    final refLogHz = <double>[];
    final semitoneDiffs = <double>[];

    for (int i = 0; i < _gridPoints; i++) {
      final u = userGrid[i];
      final r = refGrid[i];
      if (u == null || r == null || u <= 0 || r <= 0) continue;
      final uLog = math.log(u) / math.ln2;
      final rLog = math.log(r) / math.ln2;
      userLogHz.add(uLog);
      refLogHz.add(rLog);
      semitoneDiffs.add(12.0 * (uLog - rLog));
    }

    if (semitoneDiffs.length < _minCommonPoints) {
      return ReferenceComparisonResult(
        status: ReferenceComparisonStatus.available,
        message: 'Taqqoslash uchun umumiy ovozli qism yetarli emas — '
            'jumlani boshidan oxirigacha to\'liq va aniqroq ayting.',
        referenceDurationSeconds: referenceDurationSeconds,
        userDurationSeconds: userDurationSeconds,
        referenceVoicedRatio: referenceVoicedRatio,
        userVoicedRatio: userVoicedRatio,
        pitchAlignment: PitchAlignment.insufficientData,
        referenceContour: referenceContour,
        userContour: userContour,
      );
    }

    final meanDiff =
        semitoneDiffs.reduce((a, b) => a + b) / semitoneDiffs.length;
    final similarity = _pearsonSimilarity(userLogHz, refLogHz);

    final PitchAlignment alignment;
    final String message;

    if (similarity < _unstableSimilarityThreshold) {
      alignment = PitchAlignment.unstable;
      message = 'Pitch contour beqaror.';
    } else if (meanDiff > _matchedThresholdSemitones) {
      alignment = PitchAlignment.userHigher;
      message = 'Pitch reference\'dan ancha yuqori.';
    } else if (meanDiff < -_matchedThresholdSemitones) {
      alignment = PitchAlignment.userLower;
      message = 'Pitch reference\'dan ancha past.';
    } else {
      alignment = PitchAlignment.matched;
      message = 'Pitch reference bilan yaxshi mos kelmoqda.';
    }

    return ReferenceComparisonResult(
      status: ReferenceComparisonStatus.available,
      message: message,
      referenceDurationSeconds: referenceDurationSeconds,
      userDurationSeconds: userDurationSeconds,
      referenceVoicedRatio: referenceVoicedRatio,
      userVoicedRatio: userVoicedRatio,
      meanPitchDifferenceSemitones: meanDiff,
      contourSimilarity: similarity,
      pitchAlignment: alignment,
      referenceContour: referenceContour,
      userContour: userContour,
    );
  }

  /// Contourni normalize qilingan vaqt panjarasiga (0.._gridPoints-1)
  /// nearest-neighbor usulida resample qiladi. Har element voiced
  /// bo'lsa frequencyHz, aks holda null.
  List<double?> _resampleToGrid(List<PitchFrame> contour, double durationSeconds) {
    final grid = List<double?>.filled(_gridPoints, null);
    if (contour.isEmpty || durationSeconds <= 0) return grid;

    final totalMs = durationSeconds * 1000;

    for (int i = 0; i < _gridPoints; i++) {
      final targetMs = (i / (_gridPoints - 1)) * totalMs;

      PitchFrame? nearest;
      double bestDelta = double.infinity;
      for (final frame in contour) {
        final delta = (frame.timestampMs - targetMs).abs();
        if (delta < bestDelta) {
          bestDelta = delta.toDouble();
          nearest = frame;
        }
      }

      if (nearest != null && nearest.voiced) {
        grid[i] = nearest.frequencyHz;
      }
    }

    return grid;
  }

  /// Pearson korrelyatsiya koeffitsienti, 0..1 ga qisilgan.
  double _pearsonSimilarity(List<double> x, List<double> y) {
    final n = x.length;
    if (n < 2) return 0;

    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double cov = 0;
    double varX = 0;
    double varY = 0;
    for (int i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      cov += dx * dy;
      varX += dx * dx;
      varY += dy * dy;
    }

    if (varX == 0 && varY == 0) {
      // Ikkalasi ham mutlaqo tekis (o'zgarmas balandlikda) — shakl
      // ma'nosida "bir xil" hisoblanadi (darajadagi farq allaqachon
      // meanPitchDifferenceSemitones orqali alohida hisoblanadi).
      return 1.0;
    }
    if (varX == 0 || varY == 0) {
      // Faqat bittasi tekis — shakllar mos kelmaydi.
      return 0.0;
    }

    final r = cov / math.sqrt(varX * varY);
    if (r.isNaN) return 0;
    return r < 0 ? 0 : (r > 1 ? 1 : r);
  }
}
