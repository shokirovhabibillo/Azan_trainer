/// Duration/mad taqqoslash holati.
enum DurationComparisonStatus {
  /// Reference audio topilmadi — hech qanday taqqoslash bajarilmadi.
  notAvailable,

  /// Reference fayl mavjud, lekin WAV sifatida o'qib/dekodlab bo'lmadi.
  decodeError,

  /// User va reference davomiyligi real taqqoslandi.
  available,
}

/// Yagona texnik feedback turi (talab #4: diniy/tajvid hukmi emas,
/// faqat audio davomiyligi bo'yicha texnik xolat).
enum DurationFeedbackType {
  /// Ikkalasining faol (voiced) davomiyligi juda yaqin.
  veryClose,

  /// User phrase reference'dan sezilarli qisqaroq.
  userShorter,

  /// User phrase reference'dan sezilarli uzunroq.
  userLonger,

  /// Faol ovozli qism (leading/trailing silence olib tashlangandan
  /// keyingi qism) juda qisqa — ishonchli taqqoslash uchun yetarli emas.
  activeTooShort,

  /// Reference mavjud emas.
  notAvailable,
}

/// Bitta mashq uchun duration/mad tahlili natijasi.
///
/// MUHIM: bu klass hech qanday diniy/tajvid bahosi bermaydi — faqat
/// audio davomiyligi bo'yicha texnik o'lchovlar va shularga asoslangan
/// neytral feedback matnini saqlaydi. Reference mavjud bo'lmasa yoki
/// dekodlab bo'lmasa, hech qanday fake taqqoslash natijasi berilmaydi.
class DurationComparisonResult {
  final DurationComparisonStatus status;

  /// Qulaylik uchun: [status] == available bo'lsa true.
  bool get available => status == DurationComparisonStatus.available;

  /// User recordingning umumiy (fayl) davomiyligi, millisekundlarda.
  final double? userDurationMs;

  /// Reference audioning umumiy (fayl) davomiyligi, millisekundlarda.
  final double? referenceDurationMs;

  /// User recordingning "faol" (leading/trailing silence olib
  /// tashlangan, birinchi va oxirgi voiced freym orasidagi) davomiyligi.
  final double? userActiveDurationMs;

  /// Reference audioning faol davomiyligi (xuddi shu usulda).
  final double? referenceActiveDurationMs;

  /// userActiveDurationMs - referenceActiveDurationMs.
  /// Musbat = user uzunroq, manfiy = user qisqaroq.
  final double? durationDifferenceMs;

  /// userActiveDurationMs / referenceActiveDurationMs.
  final double? durationRatio;

  /// User recordingdagi voiced freymlar ulushi (0..1).
  final double? userVoicedRatio;

  /// Reference audiodagi voiced freymlar ulushi (0..1) — faqat
  /// reference mavjud bo'lganda.
  final double? referenceVoicedRatio;

  final DurationFeedbackType feedbackType;

  /// Foydalanuvchiga ko'rsatiladigan qisqa, neytral (texnik) xabar.
  final String feedback;

  const DurationComparisonResult({
    required this.status,
    required this.feedbackType,
    required this.feedback,
    this.userDurationMs,
    this.referenceDurationMs,
    this.userActiveDurationMs,
    this.referenceActiveDurationMs,
    this.durationDifferenceMs,
    this.durationRatio,
    this.userVoicedRatio,
    this.referenceVoicedRatio,
  });

  /// Reference audio umuman mavjud emasligi holati.
  factory DurationComparisonResult.notAvailable({
    double? userDurationMs,
    double? userActiveDurationMs,
    double? userVoicedRatio,
  }) {
    return DurationComparisonResult(
      status: DurationComparisonStatus.notAvailable,
      feedbackType: DurationFeedbackType.notAvailable,
      feedback: 'Reference audio mavjud emas — duration comparison '
          'bajarilmadi.',
      userDurationMs: userDurationMs,
      userActiveDurationMs: userActiveDurationMs,
      userVoicedRatio: userVoicedRatio,
    );
  }

  /// Reference fayl topildi, lekin WAV sifatida o'qib bo'lmadi.
  factory DurationComparisonResult.decodeError(
    String detail, {
    double? userDurationMs,
    double? userActiveDurationMs,
    double? userVoicedRatio,
  }) {
    return DurationComparisonResult(
      status: DurationComparisonStatus.decodeError,
      feedbackType: DurationFeedbackType.notAvailable,
      feedback: 'Reference audio o\'qib bo\'lmadi: $detail',
      userDurationMs: userDurationMs,
      userActiveDurationMs: userActiveDurationMs,
      userVoicedRatio: userVoicedRatio,
    );
  }
}
