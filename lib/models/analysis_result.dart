import 'pitch_frame.dart';
import 'reference_comparison_result.dart';

/// Bitta metrika bo'yicha holat: hali ulanmagan, yaxshi yoki tuzatish kerak.
enum MetricStatus { notConnected, good, needsWork }

class MetricResult {
  final MetricStatus status;
  final String label;

  /// Foydalanuvchiga ko'rsatiladigan qisqa izoh (masalan,
  /// "Jumla oxiridagi pitch reference'dan yuqoriga chiqdi").
  final String? note;

  const MetricResult({
    required this.status,
    required this.label,
    this.note,
  });

  const MetricResult.notConnected(String label)
      : this(
          status: MetricStatus.notConnected,
          label: label,
          note: 'Analysis module is not connected yet',
        );
}

/// Bitta mashq (recording) uchun to'liq tahlil natijasi.
///
/// MUHIM: biror metrika hali real implement qilinmagan bo'lsa, bu yerga
/// fake/tasodifiy raqam qo'yilmaydi — MetricStatus.notConnected holati
/// ishlatiladi va UI buni ochiq ko'rsatadi.
///
/// v1.1: [pitch] va [duration] endi PitchAnalyzer orqali olingan HAQIQIY
/// audio tahliliga asoslanadi (bu klassning o'zi qanday hisoblanishini
/// bilmaydi — shunchaki natijani saqlaydi).
class AnalysisResult {
  final MetricResult pitch;
  final MetricResult duration;

  /// Eng muhim bitta xato/xabar (feedback falsafasi: bittadan ko'p
  /// bermaslik). v1.1'da bu haqiqiy pitch tahliliga asoslangan xabar
  /// (masalan "Ovoz aniqlanmadi", "Pitch diapazoni aniqlandi").
  final String? topIssue;

  final DateTime createdAt;

  // --- v1.1: real pitch/F0 tahlili natijalari ---

  /// Har bir freym uchun (timestamp, frequency, voiced) — pitch contour.
  /// Grafikda chizish uchun to'g'ridan-to'g'ri ishlatilishi mumkin bo'lgan
  /// formatda (vaqt bo'yicha tartiblangan ro'yxat).
  final List<PitchFrame> pitchContour;

  /// Recordingning haqiqiy davomiyligi (sekundlarda), audio fayl
  /// o'zidan hisoblangan (yozish vaqtidan emas).
  final double? recordingDurationSeconds;

  /// Voiced freymlar orasidagi eng past aniqlangan chastota (Hz).
  final double? pitchMinHz;

  /// Voiced freymlar orasidagi eng yuqori aniqlangan chastota (Hz).
  final double? pitchMaxHz;

  /// Voiced freymlar ulushi (0..1) — jimlik/ovoz nisbati.
  final double? voicedRatio;

  /// Reference audio bilan taqqoslash holati. Reference mavjud bo'lmasa
  /// har doim [ReferenceComparisonResult.notAvailable] bo'ladi — fake
  /// taqqoslash natijasi hech qachon ko'rsatilmaydi.
  final ReferenceComparisonResult referenceComparison;

  const AnalysisResult({
    required this.pitch,
    required this.duration,
    required this.createdAt,
    required this.referenceComparison,
    this.topIssue,
    this.pitchContour = const [],
    this.recordingDurationSeconds,
    this.pitchMinHz,
    this.pitchMaxHz,
    this.voicedRatio,
  });

  bool get isFullyConnected =>
      pitch.status != MetricStatus.notConnected &&
      duration.status != MetricStatus.notConnected;

  bool get hasPitchRange => pitchMinHz != null && pitchMaxHz != null;
}
