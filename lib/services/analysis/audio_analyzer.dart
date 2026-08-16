import '../../models/analysis_result.dart';
import '../../models/phrase.dart';
import '../../models/reference_comparison_result.dart';

/// Audio tahlil moduli uchun umumiy kontrakt.
///
/// v1.1'dan boshlab asosiy implementatsiya `PitchAnalyzer`
/// (lib/services/analysis/pitch_analyzer.dart) — u haqiqiy audio
/// signalidan F0/pitch contour chiqaradi.
///
/// [UnimplementedAnalyzer] shu faylda pastda, faqat fallback/test
/// maqsadida qoldirilgan — u hech qanday fake natija bermaydi, faqat
/// hamma narsa "hali ulanmagan" ekanini bildiradi.
abstract class AudioAnalyzer {
  /// [recordingPath] — foydalanuvchi yozgan audio fayl yo'li.
  /// [referencePhrase] — solishtiriladigan reference jumla.
  Future<AnalysisResult> analyze({
    required String recordingPath,
    required Phrase referencePhrase,
  });
}

/// Fallback/test analyzer — real tahlil ishlatilmaydigan holatlar uchun.
/// Hech qanday fake/tasodifiy natija ishlab chiqarmaydi.
class UnimplementedAnalyzer implements AudioAnalyzer {
  const UnimplementedAnalyzer();

  @override
  Future<AnalysisResult> analyze({
    required String recordingPath,
    required Phrase referencePhrase,
  }) async {
    return AnalysisResult(
      pitch: const MetricResult.notConnected('Pitch (ohang)'),
      duration: const MetricResult.notConnected('Duration (cho\'zilish)'),
      topIssue: null,
      createdAt: DateTime.now(),
      referenceComparison: const ReferenceComparisonResult.notAvailable(),
    );
  }
}
