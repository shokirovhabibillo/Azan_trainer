import '../models/actor_role.dart';
import '../models/event_type.dart';
import '../models/fiqh_result.dart';
import '../models/prayer_position.dart';
import '../models/source_evidence.dart';
import '../models/prayer_type.dart';
import 'fiqh_rule.dart';

class QiraatRules {
  static bool _farz3or4(int rakat, PrayerType prayer) =>
      rakat >= 3 && rakat <= 4 &&
      {PrayerType.peshin, PrayerType.asr, PrayerType.shom, PrayerType.xufton}.contains(prayer);

  static final fatihaOmittedThirdFourthRakat = FiqhRule(
    id: 'QR-001',
    title: 'Farzning 3–4-rakatida Fotiha qoldirilishi',
    evidence: const SourceEvidence(
      sourceType: SourceType.book,
      sourceName: 'Sajdai sahv masalalari',
      section: 'Qiroat masalalari',
      verified: true,
    ),
    matches: (context, event) =>
        event.type == EventType.qiroatOmitted &&
        context.position == PrayerPosition.qiroat &&
        _farz3or4(context.rakat, context.prayerType) &&
        context.actorRole == ActorRole.munfarid,
    resolve: (context, event) => const FiqhResult(
      status: FiqhResultStatus.validContinue,
      sajdaiSahv: false,
      repeatPrayer: false,
      ruleId: 'QR-001',
      sourceName: 'Sajdai sahv masalalari',
      explanation: 'Farzning 3–4-rakatida Fotiha o‘qilmay qolishi o‘z-o‘zidan sajdai sahvni vojib qilmaydi.',
    ),
  );

  static final zamSuraAddedThirdFourthRakat = FiqhRule(
    id: 'QR-002',
    title: 'Farzning 3–4-rakatida zam sura qo‘shilishi',
    evidence: const SourceEvidence(
      sourceType: SourceType.book,
      sourceName: 'Sajdai sahv masalalari',
      section: 'Qiroat masalalari',
      verified: true,
    ),
    matches: (context, event) =>
        event.type == EventType.zamSuraAdded &&
        context.position == PrayerPosition.qiroat &&
        _farz3or4(context.rakat, context.prayerType),
    resolve: (context, event) => const FiqhResult(
      status: FiqhResultStatus.validContinue,
      sajdaiSahv: false,
      repeatPrayer: false,
      ruleId: 'QR-002',
      sourceName: 'Sajdai sahv masalalari',
      explanation: 'Farzning 3–4-rakatida zam sura qo‘shib o‘qilishi sajdai sahvni vojib qilmaydi.',
    ),
  );

  static final fatihaRepeated = FiqhRule(
    id: 'QR-003A',
    title: 'Fotiha takrorlanishi',
    evidence: const SourceEvidence(
      sourceType: SourceType.book,
      sourceName: 'Sajdai sahv masalalari',
      section: 'Qiroat masalalari',
      verified: true,
    ),
    matches: (context, event) => event.type == EventType.fatihaRepeated &&
        context.position == PrayerPosition.qiroat,
    resolve: (context, event) => const FiqhResult(
      status: FiqhResultStatus.validContinue,
      sajdaiSahv: false,
      repeatPrayer: false,
      ruleId: 'QR-003A',
      sourceName: 'Sajdai sahv masalalari',
      explanation: 'Fotiha zam suradan keyin takrorlangan holatda, manbada sajdai sahv vojib bo‘lmasligi qayd etilgan.',
    ),
  );

  static final longPauseBeforeZamSura = FiqhRule(
    id: 'QR-003',
    title: 'Fotiha bilan zam sura orasida uzoq to‘xtash',
    evidence: const SourceEvidence(
      sourceType: SourceType.book,
      sourceName: 'Sajdai sahv masalalari',
      section: 'Qiroat masalalari',
      verified: true,
    ),
    matches: (context, event) =>
        event.type == EventType.qiroatDelayed &&
        context.position == PrayerPosition.qiroat &&
        (event.delayTasbih ?? 0) >= 3,
    resolve: (context, event) => const FiqhResult(
      status: FiqhResultStatus.validWithSajdaiSahv,
      sajdaiSahv: true,
      repeatPrayer: false,
      ruleId: 'QR-003',
      sourceName: 'Sajdai sahv masalalari',
      explanation: 'Fotiha bilan zam sura orasida bir rukn/uch tasbih miqdoricha to‘xtash sahvni vojib qiladi.',
    ),
  );

  static final sameSurahInBothRakats = FiqhRule(
    id: 'QR-004',
    title: 'Bir surani ikki rak’atda takrorlash',
    evidence: const SourceEvidence(
      sourceType: SourceType.book,
      sourceName: 'Sajdai sahv masalalari',
      section: 'Qiroat masalalari',
      verified: true,
    ),
    matches: (context, event) => event.type == EventType.sameSurahRepeated,
    resolve: (context, event) => const FiqhResult(
      status: FiqhResultStatus.validContinue,
      sajdaiSahv: false,
      repeatPrayer: false,
      ruleId: 'QR-004',
      sourceName: 'Sajdai sahv masalalari',
      explanation: 'Bir surani ikki rak’atda takrorlash namozni buzmaydi va sajdai sahv talab qilmaydi; kitobda makruhligi qayd etilgan.',
    ),
  );

  static final wrongSurahOrder = FiqhRule(
    id: 'QR-005',
    title: 'Sura tartibining adashishi',
    evidence: const SourceEvidence(
      sourceType: SourceType.book,
      sourceName: 'Sajdai sahv masalalari',
      section: 'Qiroat masalalari',
      verified: true,
    ),
    matches: (context, event) => event.type == EventType.wrongSurahOrder,
    resolve: (context, event) => const FiqhResult(
      status: FiqhResultStatus.validContinue,
      sajdaiSahv: false,
      repeatPrayer: false,
      ruleId: 'QR-005',
      sourceName: 'Sajdai sahv masalalari',
      explanation: 'Sura tartibini unutib adashtirish namozni buzmaydi va sajdai sahvni talab qilmaydi. Qasddan qilishning makruhligi qayd etilgan.',
    ),
  );
}
