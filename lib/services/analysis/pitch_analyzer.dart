import 'dart:math' as math;

import '../../models/analysis_result.dart';
import '../../models/phrase.dart';
import '../../models/pitch_frame.dart';
import '../../models/reference_comparison_result.dart';
import '../audio/reference_audio_checker.dart';
import '../audio/reference_audio_loader.dart';
import 'audio_analyzer.dart';
import 'pitch_contour_extractor.dart';
import 'reference_pitch_comparator.dart';
import 'wav_decoder.dart';
import 'yin_pitch_detector.dart';

/// v1.1: Recording faylidan HAQIQIY F0/pitch contour chiqaradigan
/// analyzer. Hech qanday fake/tasodifiy qiymat ishlatmaydi.
///
/// v1.2: reference audio mavjud bo'lganda, xuddi shu pipeline reference
/// fayl uchun ham ishga tushiriladi va ikkala contour
/// [ReferencePitchComparator] orqali taqqoslanadi (vaqt bo'yicha
/// normalize qilingan semitone farq + contour similarity).
///
/// Pipeline:
///   WAV fayl → PCM namunalar (WavDecoder) → freymlarga bo'lish
///   → har freym uchun energiya (jimlik/ovoz) + YIN pitch detection
///   → pitch contour → statistikalar (range, voiced ratio, barqarorlik)
///   → feedback xabari
///
/// Reference audio hali mavjud bo'lmasa, taqqoslash umuman bajarilmaydi
/// — [ReferenceComparisonResult.notAvailable] qaytariladi.
class PitchAnalyzer implements AudioAnalyzer {
  final WavDecoder _decoder;
  final YinPitchDetector _detector;
  final ReferenceAudioChecker _referenceChecker;
  final ReferenceAudioLoader _referenceLoader;

  /// Bitta tahlil oynasi hajmi (namunalarda). 2048 @ 16kHz ≈ 128ms —
  /// past chastotali ovozlar uchun ham yetarli davr.
  final int frameSize;

  /// Freymlar orasidagi qadam (namunalarda). 50% overlap.
  final int hopSize;

  /// Jimlik chegarasi: shundan past RMS energiya "unvoiced" deb
  /// hisoblanadi (YIN natijasidan qat'i nazar).
  final double silenceRmsThreshold;

  PitchAnalyzer({
    WavDecoder decoder = const WavDecoder(),
    YinPitchDetector? detector,
    ReferenceAudioChecker referenceChecker = const ReferenceAudioChecker(),
    ReferenceAudioLoader referenceLoader = const ReferenceAudioLoader(),
    this.frameSize = 2048,
    this.hopSize = 1024,
    this.silenceRmsThreshold = 0.012,
  })  : _decoder = decoder,
        _detector = detector ?? const YinPitchDetector(),
        _referenceChecker = referenceChecker,
        _referenceLoader = referenceLoader;

  @override
  Future<AnalysisResult> analyze({
    required String recordingPath,
    required Phrase referencePhrase,
  }) async {
    final now = DateTime.now();

    final DecodedAudio audio;
    try {
      audio = await _decoder.decodeFile(recordingPath);
    } on WavDecodeException catch (e) {
      return _errorResult(now, 'Audio fayl o\'qib bo\'lmadi: ${e.message}');
    }

    final durationSeconds = audio.durationSeconds;

    // Juda qisqa recording — pitch tahlil qilish uchun ma'nosiz.
    if (durationSeconds < 0.3) {
      return _shortRecordingResult(now, durationSeconds);
    }

    final contour = _extractPitchContour(audio);
    final voicedFrames = contour.where((f) => f.voiced).toList();
    final voicedRatio =
        contour.isEmpty ? 0.0 : voicedFrames.length / contour.length;

    final referenceComparison = await _buildReferenceComparison(
      phrase: referencePhrase,
      userContour: contour,
      userDurationSeconds: durationSeconds,
      userVoicedRatio: voicedRatio,
    );

    // Hech qanday ovoz aniqlanmadi.
    if (voicedFrames.isEmpty) {
      return AnalysisResult(
        pitch: const MetricResult(
          status: MetricStatus.needsWork,
          label: 'Pitch (ohang)',
          note: 'Ovoz aniqlanmadi',
        ),
        duration: MetricResult(
          status: MetricStatus.good,
          label: 'Duration (davomiylik)',
          note: '${durationSeconds.toStringAsFixed(1)}s yozildi',
        ),
        topIssue: 'Ovoz aniqlanmadi. Mikrofonga yaqinroq va balandroq '
            'ovozda qayta urinib ko\'ring.',
        createdAt: now,
        pitchContour: contour,
        recordingDurationSeconds: durationSeconds,
        voicedRatio: voicedRatio,
        referenceComparison: referenceComparison,
      );
    }

    // Voiced freymlar bor, lekin juda kam — ishonchli statistika
    // chiqarish uchun yetarli emas.
    if (voicedFrames.length < 3) {
      return AnalysisResult(
        pitch: const MetricResult(
          status: MetricStatus.needsWork,
          label: 'Pitch (ohang)',
          note: 'Pitch ma\'lumotlari yetarli emas',
        ),
        duration: MetricResult(
          status: MetricStatus.good,
          label: 'Duration (davomiylik)',
          note: '${durationSeconds.toStringAsFixed(1)}s yozildi',
        ),
        topIssue: 'Ovoz juda qisqa yoki uzuq-uzuq aniqlandi. Jumlani '
            'to\'liq va bir maromda ayting.',
        createdAt: now,
        pitchContour: contour,
        recordingDurationSeconds: durationSeconds,
        voicedRatio: voicedRatio,
        referenceComparison: referenceComparison,
      );
    }

    final freqs = voicedFrames.map((f) => f.frequencyHz).toList();
    final minHz = freqs.reduce((a, b) => a < b ? a : b);
    final maxHz = freqs.reduce((a, b) => a > b ? a : b);
    final mean = freqs.reduce((a, b) => a + b) / freqs.length;
    final variance =
        freqs.map((f) => (f - mean) * (f - mean)).reduce((a, b) => a + b) /
            freqs.length;
    final stdDev = variance > 0 ? math.sqrt(variance) : 0.0;
    // Barqarorlik: standart chetlanish o'rtacha chastotaga nisbatan
    // qancha kichik bo'lsa, ohang shuncha barqaror.
    final stabilityRatio = mean == 0 ? 1.0 : stdDev / mean;
    final isStable = stabilityRatio < 0.15;

    final pitchNote = 'Diapazon: ${minHz.round()}–${maxHz.round()} Hz, '
        'barqarorlik: ${isStable ? "yaxshi" : "past"}';

    final topIssue = isStable
        ? 'Pitch diapazoni aniqlandi (${minHz.round()}–${maxHz.round()} Hz), '
            'ohang barqaror.'
        : 'Pitch diapazoni aniqlandi (${minHz.round()}–${maxHz.round()} Hz), '
            'lekin ohang tebranishi ko\'p — bir xil balandlikda '
            'cho\'zishga harakat qiling.';

    return AnalysisResult(
      pitch: MetricResult(
        status: MetricStatus.good,
        label: 'Pitch (ohang)',
        note: pitchNote,
      ),
      duration: MetricResult(
        status: MetricStatus.good,
        label: 'Duration (davomiylik)',
        note: '${durationSeconds.toStringAsFixed(1)}s yozildi',
      ),
      topIssue: topIssue,
      createdAt: now,
      pitchContour: contour,
      recordingDurationSeconds: durationSeconds,
      pitchMinHz: minHz,
      pitchMaxHz: maxHz,
      voicedRatio: voicedRatio,
      referenceComparison: referenceComparison,
    );
  }

  List<PitchFrame> _extractPitchContour(DecodedAudio audio) {
    // v1.2: endi umumiy PitchContourExtractor'ga delegatsiya qilinadi —
    // bir xil kod endi reference audio uchun ham ishlatiladi. Algoritm
    // (freymlash, RMS jimlik chegarasi, YIN chaqiruvi) v1.1'dagi bilan
    // bir xil, faqat bir joyga ko'chirilgan.
    final extractor = PitchContourExtractor(
      detector: _detector,
      frameSize: frameSize,
      hopSize: hopSize,
      silenceRmsThreshold: silenceRmsThreshold,
    );
    return extractor.extract(audio);
  }

  /// v1.2: reference audio uchun ham AYNAN bir xil pipeline
  /// (ReferenceAudioLoader → WavDecoder → PitchContourExtractor →
  /// bir xil YinPitchDetector) ishlatiladi, keyin ikkala contour
  /// [ReferencePitchComparator] orqali taqqoslanadi.
  ///
  /// Reference fayl topilmasa yoki WAV sifatida o'qib bo'lmasa, fake
  /// natija hech qachon qaytarilmaydi — holat ochiq belgilanadi.
  Future<ReferenceComparisonResult> _buildReferenceComparison({
    required Phrase phrase,
    required List<PitchFrame> userContour,
    required double userDurationSeconds,
    required double userVoicedRatio,
  }) async {
    final exists = await _referenceChecker.exists(phrase.referenceAudioFile);
    if (!exists) {
      return const ReferenceComparisonResult.notAvailable();
    }

    final DecodedAudio referenceAudio;
    try {
      referenceAudio = await _referenceLoader.load(phrase.referenceAudioFile);
    } on ReferenceAudioLoadException catch (e) {
      return ReferenceComparisonResult.decodeError(e.message);
    }

    final extractor = PitchContourExtractor(
      detector: _detector,
      frameSize: frameSize,
      hopSize: hopSize,
      silenceRmsThreshold: silenceRmsThreshold,
    );
    final referenceContour = extractor.extract(referenceAudio);
    final referenceVoicedFrames =
        referenceContour.where((f) => f.voiced).toList();
    final referenceVoicedRatio = referenceContour.isEmpty
        ? 0.0
        : referenceVoicedFrames.length / referenceContour.length;

    return const ReferencePitchComparator().compare(
      userContour: userContour,
      userDurationSeconds: userDurationSeconds,
      userVoicedRatio: userVoicedRatio,
      referenceContour: referenceContour,
      referenceDurationSeconds: referenceAudio.durationSeconds,
      referenceVoicedRatio: referenceVoicedRatio,
    );
  }

  AnalysisResult _shortRecordingResult(
    DateTime now,
    double durationSeconds,
  ) {
    return AnalysisResult(
      pitch: const MetricResult(
        status: MetricStatus.needsWork,
        label: 'Pitch (ohang)',
        note: 'Ovoz juda qisqa',
      ),
      duration: MetricResult(
        status: MetricStatus.needsWork,
        label: 'Duration (davomiylik)',
        note: '${durationSeconds.toStringAsFixed(2)}s (juda qisqa)',
      ),
      topIssue: 'Recording juda qisqa (${durationSeconds.toStringAsFixed(2)}s). '
          'Jumlani to\'liq aytib, keyin to\'xtatish tugmasini bosing.',
      createdAt: now,
      recordingDurationSeconds: durationSeconds,
      referenceComparison: const ReferenceComparisonResult.notAvailable(),
    );
  }

  AnalysisResult _errorResult(DateTime now, String message) {
    return AnalysisResult(
      pitch: MetricResult(
        status: MetricStatus.needsWork,
        label: 'Pitch (ohang)',
        note: message,
      ),
      duration: const MetricResult(
        status: MetricStatus.needsWork,
        label: 'Duration (davomiylik)',
        note: 'Aniqlanmadi',
      ),
      topIssue: message,
      createdAt: now,
      referenceComparison: const ReferenceComparisonResult.notAvailable(),
    );
  }

}
