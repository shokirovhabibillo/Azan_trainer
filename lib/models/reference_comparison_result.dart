import 'pitch_frame.dart';

enum ReferenceComparisonStatus {
  /// Reference audio fayli topilmadi — hech qanday taqqoslash bajarilmadi.
  notAvailable,

  /// Reference fayl mavjud, lekin WAV sifatida o'qib/dekodlab bo'lmadi
  /// (masalan, format noto'g'ri yoki fayl buzilgan).
  decodeError,

  /// v1.1'da ishlatilgan holat: fayl bor, lekin taqqoslash hali
  /// implement qilinmagan edi. v1.2'dan boshlab bu holat ishlatilmaydi,
  /// lekin backward-compat uchun saqlanadi.
  notImplemented,

  /// Reference va user contour real taqqoslandi.
  available,
}

/// Ikki pitch contour (F0/Hz bo'yicha vaqt qatorlari) qanchalik mos
/// kelishini umumlashtiruvchi holat.
enum PitchAlignment {
  /// Umumiy voiced nuqtalar reference bilan mos (o'rtacha semitone farq
  /// kichik).
  matched,

  /// User ovozi reference'dan sezilarli darajada yuqori.
  userHigher,

  /// User ovozi reference'dan sezilarli darajada past.
  userLower,

  /// Contour shakli beqaror/mos kelmaydi (past similarity).
  unstable,

  /// Ikkala contourda ham umumiy voiced nuqta yetarli emas — hisoblash
  /// ishonchli emas.
  insufficientData,
}

/// Foydalanuvchi pitch contourini reference audio bilan solishtirish
/// natijasi.
///
/// Reference mavjud bo'lmasa yoki dekodlab bo'lmasa, hech qanday fake
/// taqqoslash natijasi qaytarilmaydi — faqat holat va tushunarli xabar.
class ReferenceComparisonResult {
  final ReferenceComparisonStatus status;
  final String message;

  // --- v1.2: real taqqoslash natijalari (faqat status == available'da) ---

  final double? referenceDurationSeconds;
  final double? userDurationSeconds;

  final double? referenceVoicedRatio;
  final double? userVoicedRatio;

  /// O'rtacha pitch farqi, semitonlarda: 12 * log2(userHz / refHz),
  /// umumiy (ikkalasi ham voiced bo'lgan) nuqtalar bo'yicha o'rtacha.
  /// Musbat = user reference'dan yuqori, manfiy = past.
  final double? meanPitchDifferenceSemitones;

  /// Contour shakli o'xshashligi, 0..1. Formula:
  /// Pearson korrelyatsiya koeffitsienti (log2-chastota qatorlari
  /// bo'yicha), 0 va 1 oralig'iga qisilgan (manfiy korrelyatsiya = 0).
  /// 1 ga yaqin — ikkala contour bir xil ko'tarilish/tushish shakliga
  /// ega; 0 ga yaqin — shakllar orasida bog'liqlik yo'q.
  final double? contourSimilarity;

  final PitchAlignment? pitchAlignment;

  final List<PitchFrame> referenceContour;
  final List<PitchFrame> userContour;

  const ReferenceComparisonResult({
    required this.status,
    required this.message,
    this.referenceDurationSeconds,
    this.userDurationSeconds,
    this.referenceVoicedRatio,
    this.userVoicedRatio,
    this.meanPitchDifferenceSemitones,
    this.contourSimilarity,
    this.pitchAlignment,
    this.referenceContour = const [],
    this.userContour = const [],
  });

  const ReferenceComparisonResult.notAvailable()
      : this(
          status: ReferenceComparisonStatus.notAvailable,
          message: 'Reference audio mavjud emas — taqqoslash bajarilmadi.',
        );

  const ReferenceComparisonResult.notImplemented()
      : this(
          status: ReferenceComparisonStatus.notImplemented,
          message: 'Reference audio topildi, lekin taqqoslash algoritmi '
              'hali keyingi bosqichda qo\'shiladi.',
        );

  factory ReferenceComparisonResult.decodeError(String detail) {
    return ReferenceComparisonResult(
      status: ReferenceComparisonStatus.decodeError,
      message: 'Reference audio o\'qib bo\'lmadi: $detail',
    );
  }

  bool get isAvailable => status == ReferenceComparisonStatus.available;
}
