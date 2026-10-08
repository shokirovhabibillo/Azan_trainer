import 'fiqh_rule.dart';
import 'qiraat_rules.dart';
import 'sahv_rules.dart';

class RuleRegistry {
  static final List<FiqhRule> rules = [
    QiraatRules.fatihaOmittedThirdFourthRakat,
    QiraatRules.zamSuraAddedThirdFourthRakat,
    QiraatRules.fatihaRepeated,
    QiraatRules.longPauseBeforeZamSura,
    QiraatRules.sameSurahInBothRakats,
    QiraatRules.wrongSurahOrder,
    SahvRules.repeatedRuku,
    SahvRules.repeatedSajda,
  ];
}
