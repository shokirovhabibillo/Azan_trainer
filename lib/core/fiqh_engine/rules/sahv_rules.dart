import '../models/event_type.dart';
import '../models/fiqh_result.dart';
import '../models/source_evidence.dart';
import 'fiqh_rule.dart';

class SahvRules {
  static final repeatedRuku = FiqhRule(
    id: 'SAHV-001',
    title: 'Ruku’ni takrorlash',
    evidence: const SourceEvidence(
      sourceType: SourceType.book,
      sourceName: 'Sajdai sahv masalalari',
      section: 'Ruku’ va sajda masalalari',
      verified: true,
    ),
    matches: (context, event) => event.type == EventType.rukuRepeated,
    resolve: (context, event) => const FiqhResult(
      status: FiqhResultStatus.validWithSajdaiSahv,
      sajdaiSahv: true,
      repeatPrayer: false,
      ruleId: 'SAHV-001',
      sourceName: 'Sajdai sahv masalalari',
      explanation: 'Ruku’ni tasodifan takrorlash sahv sajdasini talab qiladigan holatlardan biri sifatida keltirilgan.',
    ),
  );

  static final repeatedSajda = FiqhRule(
    id: 'SAHV-002',
    title: 'Sajdani ortiqcha takrorlash',
    evidence: const SourceEvidence(
      sourceType: SourceType.book,
      sourceName: 'Sajdai sahv masalalari',
      section: 'Ruku’ va sajda masalalari',
      verified: true,
    ),
    matches: (context, event) => event.type == EventType.sajdaRepeated,
    resolve: (context, event) => const FiqhResult(
      status: FiqhResultStatus.validWithSajdaiSahv,
      sajdaiSahv: true,
      repeatPrayer: false,
      ruleId: 'SAHV-002',
      sourceName: 'Sajdai sahv masalalari',
      explanation: 'Sajdani tasodifan ortiqcha qilish bilan bog‘liq sahv holati manbada sajdai sahv bilan tuzatiladigan holat sifatida keltirilgan.',
    ),
  );
}
