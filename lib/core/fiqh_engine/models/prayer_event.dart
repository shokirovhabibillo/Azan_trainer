import 'event_type.dart';
import 'prayer_position.dart';

class PrayerEvent {
  final EventType type;
  final PrayerPosition position;
  final bool intentional;
  final bool? corrected;
  final int? delayTasbih;

  const PrayerEvent({
    required this.type,
    required this.position,
    this.intentional = false,
    this.corrected,
    this.delayTasbih,
  });
}
