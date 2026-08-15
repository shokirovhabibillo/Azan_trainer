import '../../models/pitch_frame.dart';
import '../audio/reference_audio_loader.dart';
import 'pitch_contour_extractor.dart';

/// v1.14: real-vaqt grafigi uchun reference audioning pitch konturini
/// OLDINDAN (recording boshlanishidan oldin) hisoblab qo'yadi.
///
/// MUHIM: bu klass hech qanday yangi tahlil algoritmi YARATMAYDI —
/// faqat mavjud, tasdiqlangan `ReferenceAudioLoader` (WAV o'qish) va
/// `PitchContourExtractor` (v1.1'dan tasdiqlangan, o'zgartirilmagan)
/// pipeline'ini, xuddi ResultScreen post-hoc tahlilda ishlatgani
/// kabi, faqat OLDINDAN chaqiradi.
class ReferenceContourPrecomputer {
  final ReferenceAudioLoader _loader;
  final PitchContourExtractor _extractor;

  const ReferenceContourPrecomputer({
    ReferenceAudioLoader loader = const ReferenceAudioLoader(),
    PitchContourExtractor extractor = const PitchContourExtractor(),
  })  : _loader = loader,
        _extractor = extractor;

  /// Reference audio topilmasa yoki noto'g'ri formatda bo'lsa, `null`
  /// qaytaradi — chaqiruvchi UI shu holatda "Na'muna ovoz mavjud
  /// emas" ko'rsatishi kerak.
  Future<PrecomputedReferenceContour?> precompute(
    String referenceAudioFile,
  ) async {
    try {
      final decoded = await _loader.load(referenceAudioFile);
      final contour = _extractor.extract(decoded);
      return PrecomputedReferenceContour(
        contour: contour,
        durationSeconds: decoded.durationSeconds,
      );
    } on ReferenceAudioLoadException {
      return null;
    }
  }
}

class PrecomputedReferenceContour {
  final List<PitchFrame> contour;
  final double durationSeconds;

  const PrecomputedReferenceContour({
    required this.contour,
    required this.durationSeconds,
  });
}
