import 'models/fiqh_result.dart';
import 'models/prayer_context.dart';
import 'models/prayer_event.dart';
import 'rules/rule_registry.dart';

class RuleEngine {
  FiqhResult evaluate({
    required PrayerContext context,
    required PrayerEvent event,
  }) {
    for (final rule in RuleRegistry.rules) {
      if (rule.matches(context, event)) {
        return rule.resolve(context, event);
      }
    }

    return const FiqhResult(
      status: FiqhResultStatus.needsSourceVerification,
      sajdaiSahv: false,
      repeatPrayer: false,
      explanation: 'Bu holat uchun hozircha tekshirilgan qoida topilmadi.',
    );
  }
}
