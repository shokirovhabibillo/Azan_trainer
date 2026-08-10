/// Bitta tahlil freymi uchun pitch ma'lumoti.
///
/// Pitch contour — shu freymlar ro'yxati — kelajakda grafikda chizish
/// uchun to'g'ridan-to'g'ri ishlatilishi mumkin: har bir nuqta
/// (timestampMs, frequencyHz) juftligi.
class PitchFrame {
  /// Recording boshidan necha millisekund o'tganda ushbu freym olingani.
  final int timestampMs;

  /// Aniqlangan asosiy chastota (Hz). Unvoiced freymlarda 0.0.
  final double frequencyHz;

  /// Ushbu freymda ovoz (voiced signal) aniqlanganmi.
  final bool voiced;

  const PitchFrame({
    required this.timestampMs,
    required this.frequencyHz,
    required this.voiced,
  });

  Map<String, dynamic> toJson() => {
        'timestampMs': timestampMs,
        'frequencyHz': frequencyHz,
        'voiced': voiced,
      };
}
