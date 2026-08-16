import 'analysis_result.dart';
import 'duration_comparison_result.dart';

/// v1.7: bitta jumla uchun TO'LIQ amaliyot holati — yozib olingan
/// audio HAM tahlil natijasi.
///
/// Bu klass `PracticeSessionController`da jumla ID (`Phrase.id`)
/// bo'yicha xaritada saqlanadi — "single source of truth". Jumla
/// almashtirilganda `PhrasePracticeScreen`ning o'zi (State) yo'q
/// qilinsa ham, bu ma'lumot yo'qolmaydi, chunki u ota-ona
/// (`PracticeScreen`) darajasida saqlanadi.
///
/// MUHIM: bu klass faqat SAQLASH/TIKLASH uchun — hech qanday tahlil
/// mantig'ini o'z ichiga olmaydi. `AnalysisResult` va
/// `DurationComparisonResult` obyektlari `PitchAnalyzer`/
/// `DurationAnalyzer` orqali hisoblanadi (o'zgarmagan holda); bu yerda
/// faqat ULARNING NATIJASI keyinroq qayta ko'rsatish uchun saqlanadi.
class PhrasePracticeState {
  /// Yozib olingan audio fayl yo'li. Fayl mavjud bo'lmasa (masalan,
  /// o'chirilgan bo'lsa), bu qiymat "amalda mavjud" deb hisoblanmaydi —
  /// buni tekshirish `PhrasePracticeScreen`ning o'zida (fayl tizimidan)
  /// amalga oshiriladi, bu model faqat yo'lni saqlaydi.
  final String? recordingPath;
  final Duration recordingDuration;

  /// v1.3 `PitchAnalyzer` orqali hisoblangan tayyor natija (keshlangan).
  final AnalysisResult? analysisResult;

  /// v1.4 `DurationAnalyzer` orqali hisoblangan tayyor natija
  /// (keshlangan).
  final DurationComparisonResult? durationResult;

  const PhrasePracticeState({
    this.recordingPath,
    this.recordingDuration = Duration.zero,
    this.analysisResult,
    this.durationResult,
  });

  bool get hasRecording => recordingPath != null;

  bool get hasAnalysis => analysisResult != null && durationResult != null;

  /// Yangi recording yozilganda ishlatiladi. Eski tahlil natijasi
  /// ATAYLAB bekor qilinadi — chunki u ESKI audioga tegishli edi, yangi
  /// audio bilan mos emas (talab #4: analysis phrase bilan emas,
  /// aslida AUDIO bilan bog'liq bo'lishi kerak).
  PhrasePracticeState withNewRecording({
    required String recordingPath,
    required Duration recordingDuration,
  }) {
    return PhrasePracticeState(
      recordingPath: recordingPath,
      recordingDuration: recordingDuration,
      analysisResult: null,
      durationResult: null,
    );
  }

  /// Tahlil natijasi hisoblangandan keyin, mavjud recordingni saqlab
  /// qolgan holda, natijani biriktirish uchun ishlatiladi.
  PhrasePracticeState withAnalysis({
    required AnalysisResult analysisResult,
    required DurationComparisonResult durationResult,
  }) {
    return PhrasePracticeState(
      recordingPath: recordingPath,
      recordingDuration: recordingDuration,
      analysisResult: analysisResult,
      durationResult: durationResult,
    );
  }

  /// Recording butunlay bekor qilinganda (masalan, "Qayta yozish"
  /// bosilganda, yozib bo'lgunga qadar) ishlatiladigan bo'sh holat.
  static const empty = PhrasePracticeState();
}
