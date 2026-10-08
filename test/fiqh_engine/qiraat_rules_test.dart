import 'package:flutter_test/flutter_test.dart';
import 'package:tartib_fiqh_engine/core/fiqh_engine/models/actor_role.dart';
import 'package:tartib_fiqh_engine/core/fiqh_engine/models/event_type.dart';
import 'package:tartib_fiqh_engine/core/fiqh_engine/models/fiqh_result.dart';
import 'package:tartib_fiqh_engine/core/fiqh_engine/models/prayer_context.dart';
import 'package:tartib_fiqh_engine/core/fiqh_engine/models/prayer_event.dart';
import 'package:tartib_fiqh_engine/core/fiqh_engine/models/prayer_position.dart';
import 'package:tartib_fiqh_engine/core/fiqh_engine/models/prayer_type.dart';
import 'package:tartib_fiqh_engine/core/fiqh_engine/rule_engine.dart';

void main() {
  final engine = RuleEngine();

  PrayerContext c({int rakat = 3, ActorRole role = ActorRole.munfarid, PrayerPosition position = PrayerPosition.qiroat}) => PrayerContext(
    prayerType: PrayerType.asr, rakat: rakat, actorRole: role, position: position,
  );

  test('QR-001: 3-rakat farz, Fotiha omitted', () {
    final r = engine.evaluate(context: c(), event: const PrayerEvent(type: EventType.qiroatOmitted, position: PrayerPosition.qiroat));
    expect(r.status, FiqhResultStatus.validContinue);
    expect(r.sajdaiSahv, isFalse);
    expect(r.repeatPrayer, isFalse);
  });

  test('QR-002: 3-rakat farz, extra zam sura', () {
    final r = engine.evaluate(context: c(), event: const PrayerEvent(type: EventType.zamSuraAdded, position: PrayerPosition.qiroat));
    expect(r.ruleId, 'QR-002');
    expect(r.sajdaiSahv, isFalse);
  });

  test('QR-003: long pause before zam sura', () {
    final r = engine.evaluate(context: c(), event: const PrayerEvent(type: EventType.qiroatDelayed, position: PrayerPosition.qiroat, delayTasbih: 3));
    expect(r.status, FiqhResultStatus.validWithSajdaiSahv);
    expect(r.sajdaiSahv, isTrue);
  });

  test('QR-004: same surah repeated', () {
    final r = engine.evaluate(context: c(), event: const PrayerEvent(type: EventType.sameSurahRepeated, position: PrayerPosition.qiroat));
    expect(r.ruleId, 'QR-004');
    expect(r.sajdaiSahv, isFalse);
  });

  test('SAHV-001: repeated ruku', () {
    final r = engine.evaluate(context: c(position: PrayerPosition.ruku), event: const PrayerEvent(type: EventType.rukuRepeated, position: PrayerPosition.ruku));
    expect(r.ruleId, 'SAHV-001');
    expect(r.sajdaiSahv, isTrue);
  });

  test('unmatched case is not guessed', () {
    final r = engine.evaluate(context: c(rakat: 1), event: const PrayerEvent(type: EventType.qiroatOmitted, position: PrayerPosition.qiroat));
    expect(r.status, FiqhResultStatus.needsSourceVerification);
  });
}
