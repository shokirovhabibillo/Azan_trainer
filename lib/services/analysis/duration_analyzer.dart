import '../../models/duration_comparison_result.dart';
import '../../models/phrase.dart';
import '../audio/reference_audio_checker.dart';
import '../audio/reference_audio_loader.dart';
import 'pitch_contour_extractor.dart';
import 'wav_decoder.dart';

/// Bitta tomon (user yoki reference) uchun o'lchangan davomiylik
/// ma'lumotlari. Faqat shu fayl ichida ishlatiladigan yordamchi tuzilma.
class _DurationMeasurement {
  final double totalDurationMs;
  final double activeDurationMs;
  final double voicedRatio;

  const _DurationMeasurement({
    required this.totalDurationMs,
    required this.activeDurationMs,
    required this.voicedRatio,
  });
}

/// v1.4: User recording va reference audio davomiyligini (mad/cho'zilish)
/// solishtiradigan MUSTAQIL analyzer.
///
/// MUHIM — mustaqillik: bu klass `PitchAnalyzer`dan butunlay ajratilgan
/// — o'z ichida WavDecoder va PitchContourExtractor'ni (ikkalasi ham
/// v1.3'dan beri o'zgarmagan) mustaqil chaqiradi. `PitchAnalyzer`,
/// `ReferencePitchComparator` va `DurationAnalyzer` bir-biriga qattiq
/// bog'lanmagan — ResultScreen ularni alohida-alohida chaqiradi va
/// natijalarni faqat ko'rsatish uchun birlashtiradi.
///
/// Pipeline:
///   User WAV → WavDecoder → PitchContourExtractor
///     → total duration + faol (voiced) davomiylik
///   Reference WAV (agar mavjud bo'lsa) → xuddi shu pipeline
///     → total duration + faol davomiylik
///   → duration ratio, farq, threshold-based texnik feedback
///
/// "Faol davomiylik" — birinchi va oxirgi voiced freym orasidagi
/// oraliq (+ bitta hop davomiyligi) — bu orqali recording boshidagi va
/// oxiridagi jimlik (masalan, foydalanuvchi tugmani bosib, keyin
/// gapira boshlagan vaqt) umumiy davomiylikka noto'g'ri ta'sir
/// qilmaydi.
///
/// Bu klass hech qanday diniy/tajvid hukmi chiqarmaydi — faqat texnik
/// o'lchov va shu asosdagi neytral xabar beradi.
class DurationAnalyzer {
  final WavDecoder _decoder;
  final PitchContourExtractor _extractor;
  final ReferenceAudioChecker _referenceChecker;
  final ReferenceAudioLoader _referenceLoader;

  // --- Threshold konstantalari ---
  // Bular hozircha oddiy texnik chegaralar. Kelajakda tajvid/mad
  // ekspertizasi asosida (masalan, harf turiga qarab farqli
  // me'yorlar bilan) almashtirilishi mumkin — shuning uchun alohida
  // nomlangan constant sifatida saqlanadi, kod ichiga "singdirilmaydi".

  /// Faol davomiylik shundan qisqa bo'lsa, ishonchli taqqoslash uchun
  /// yetarli emas deb hisoblanadi.
  static const double minActiveDurationMs = 300;

  /// Ratio shu oraliqda bo'lsa — "juda yaqin" deb hisoblanadi.
  static const double closeRatioLowerBound = 0.85;
  static const double closeRatioUpperBound = 1.15;

  const DurationAnalyzer({
    WavDecoder decoder = const WavDecoder(),
    PitchContourExtractor extractor = const PitchContourExtractor(),
    ReferenceAudioChecker referenceChecker = const ReferenceAudioChecker(),
    ReferenceAudioLoader referenceLoader = const ReferenceAudioLoader(),
  })  : _decoder = decoder,
        _extractor = extractor,
        _referenceChecker = referenceChecker,
        _referenceLoader = referenceLoader;

  Future<DurationComparisonResult> analyze({
    required String recordingPath,
    required Phrase referencePhrase,
  }) async {
    final DecodedAudio userAudio;
    try {
      userAudio = await _decoder.decodeFile(recordingPath);
    } on WavDecodeException {
      // Audio fayl o'qib bo'lmadi — bu holat PitchAnalyzer tomonidan
      // ham qamrab olinadi; duration tomonda shunchaki "mavjud emas"
      // holatiga tushamiz (fake son bermaymiz).
      return DurationComparisonResult.notAvailable();
    }

    final userMeasurement = _measure(userAudio);

    final exists = await _referenceChecker.exists(
      referencePhrase.referenceAudioFile,
    );
    if (!exists) {
      return DurationComparisonResult.notAvailable(
        userDurationMs: userMeasurement.totalDurationMs,
        userActiveDurationMs: userMeasurement.activeDurationMs,
        userVoicedRatio: userMeasurement.voicedRatio,
      );
    }

    final DecodedAudio referenceAudio;
    try {
      referenceAudio = await _referenceLoader.load(
        referencePhrase.referenceAudioFile,
      );
    } on ReferenceAudioLoadException catch (e) {
      return DurationComparisonResult.decodeError(
        e.message,
        userDurationMs: userMeasurement.totalDurationMs,
        userActiveDurationMs: userMeasurement.activeDurationMs,
        userVoicedRatio: userMeasurement.voicedRatio,
      );
    }

    final referenceMeasurement = _measure(referenceAudio);

    return _compare(userMeasurement, referenceMeasurement);
  }

  _DurationMeasurement _measure(DecodedAudio audio) {
    final totalMs = audio.durationSeconds * 1000;
    final contour = _extractor.extract(audio);

    if (contour.isEmpty) {
      return _DurationMeasurement(
        totalDurationMs: totalMs,
        activeDurationMs: 0,
        voicedRatio: 0,
      );
    }

    final voicedFrames = contour.where((f) => f.voiced).toList();
    final voicedRatio = voicedFrames.length / contour.length;

    if (voicedFrames.isEmpty) {
      return _DurationMeasurement(
        totalDurationMs: totalMs,
        activeDurationMs: 0,
        voicedRatio: 0,
      );
    }

    final hopMs = _extractor.hopSize / audio.sampleRate * 1000;
    final firstMs = voicedFrames.first.timestampMs;
    final lastMs = voicedFrames.last.timestampMs;
    final activeMs = (lastMs - firstMs).toDouble() + hopMs;

    return _DurationMeasurement(
      totalDurationMs: totalMs,
      activeDurationMs: activeMs,
      voicedRatio: voicedRatio,
    );
  }

  DurationComparisonResult _compare(
    _DurationMeasurement user,
    _DurationMeasurement reference,
  ) {
    if (user.activeDurationMs < minActiveDurationMs ||
        reference.activeDurationMs < minActiveDurationMs) {
      return DurationComparisonResult(
        status: DurationComparisonStatus.available,
        feedbackType: DurationFeedbackType.activeTooShort,
        feedback: 'Faol ovozli qism juda qisqa.',
        userDurationMs: user.totalDurationMs,
        referenceDurationMs: reference.totalDurationMs,
        userActiveDurationMs: user.activeDurationMs,
        referenceActiveDurationMs: reference.activeDurationMs,
        durationDifferenceMs: user.activeDurationMs - reference.activeDurationMs,
        durationRatio: reference.activeDurationMs == 0
            ? null
            : user.activeDurationMs / reference.activeDurationMs,
        userVoicedRatio: user.voicedRatio,
        referenceVoicedRatio: reference.voicedRatio,
      );
    }

    final ratio = user.activeDurationMs / reference.activeDurationMs;
    final diff = user.activeDurationMs - reference.activeDurationMs;

    final DurationFeedbackType feedbackType;
    final String feedback;
    if (ratio >= closeRatioLowerBound && ratio <= closeRatioUpperBound) {
      feedbackType = DurationFeedbackType.veryClose;
      feedback = 'Reference bilan davomiylik juda yaqin.';
    } else if (ratio < closeRatioLowerBound) {
      feedbackType = DurationFeedbackType.userShorter;
      feedback = 'User phrase reference\'dan qisqaroq.';
    } else {
      feedbackType = DurationFeedbackType.userLonger;
      feedback = 'User phrase reference\'dan uzunroq.';
    }

    return DurationComparisonResult(
      status: DurationComparisonStatus.available,
      feedbackType: feedbackType,
      feedback: feedback,
      userDurationMs: user.totalDurationMs,
      referenceDurationMs: reference.totalDurationMs,
      userActiveDurationMs: user.activeDurationMs,
      referenceActiveDurationMs: reference.activeDurationMs,
      durationDifferenceMs: diff,
      durationRatio: ratio,
      userVoicedRatio: user.voicedRatio,
      referenceVoicedRatio: reference.voicedRatio,
    );
  }
}
