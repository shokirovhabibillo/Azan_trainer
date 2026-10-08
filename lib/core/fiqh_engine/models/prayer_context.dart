import 'actor_role.dart';
import 'prayer_position.dart';
import 'prayer_type.dart';

class PrayerContext {
  final PrayerType prayerType;
  final int rakat;
  final ActorRole actorRole;
  final PrayerPosition position;
  final bool? jahr;
  final bool? imamPresent;

  const PrayerContext({
    required this.prayerType,
    required this.rakat,
    required this.actorRole,
    required this.position,
    this.jahr,
    this.imamPresent,
  });
}
