import '../models/fiqh_result.dart';
import '../models/prayer_context.dart';
import '../models/prayer_event.dart';
import '../models/source_evidence.dart';

typedef RuleMatcher = bool Function(PrayerContext context, PrayerEvent event);
typedef RuleResolver = FiqhResult Function(PrayerContext context, PrayerEvent event);

class FiqhRule {
  final String id;
  final String title;
  final RuleMatcher matches;
  final RuleResolver resolve;
  final SourceEvidence evidence;

  const FiqhRule({
    required this.id,
    required this.title,
    required this.matches,
    required this.resolve,
    required this.evidence,
  });
}
