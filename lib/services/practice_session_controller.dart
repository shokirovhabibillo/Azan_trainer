import '../models/phrase_practice_state.dart';

/// v1.7: bitta mashq sessiyasi (masalan, "Azon" yoki "Bomdod azoni")
/// davomida barcha jumlalarning holatini (recording + tahlil) jumla ID
/// bo'yicha saqlaydigan controller.
///
/// Bu klass SOF Dart — Flutter widget'lariga yoki platform kanallariga
/// (mikrofon, fayl tizimi) bog'liq emas, shuning uchun to'g'ridan-to'g'ri
/// unit-test qilinadi.
///
/// Hozircha faqat sessiya davomida (xotirada) saqlaydi — talab #6
/// bo'yicha, bu ATAYLAB oddiy qilib qoldirilgan: kelajakda
/// `PracticeSessionController`ni Hive/SQLite/SharedPreferences bilan
/// ta'minlovchi implementatsiya bilan almashtirish (yoki shu klassga
/// `load()`/`persist()` metodlarini qo'shish) oson bo'ladi, chunki
/// butun ilova shu bitta interfeys orqali ishlaydi.
class PracticeSessionController {
  final Map<String, PhrasePracticeState> _states = {};

  /// Berilgan jumla uchun saqlangan holatni qaytaradi (yoki hech narsa
  /// saqlanmagan bo'lsa `null`).
  PhrasePracticeState? stateFor(String phraseId) => _states[phraseId];

  /// Jumla holatini yangilaydi. `state == null` bo'lsa, jumla xaritadan
  /// butunlay olib tashlanadi (masalan, recording bekor qilinganda).
  void update(String phraseId, PhrasePracticeState? state) {
    if (state == null) {
      _states.remove(phraseId);
    } else {
      _states[phraseId] = state;
    }
  }

  /// Barcha saqlangan holatlarning o'zgarmas (immutable) nusxasi —
  /// masalan, "Natijalar" ro'yxati ekranini chizish uchun.
  Map<String, PhrasePracticeState> get all => Map.unmodifiable(_states);

  /// Nechta jumla uchun recording mavjudligini hisoblaydi.
  int get recordedCount =>
      _states.values.where((s) => s.hasRecording).length;

  /// Nechta jumla uchun tahlil natijasi mavjudligini hisoblaydi.
  int get analyzedCount => _states.values.where((s) => s.hasAnalysis).length;

  void clearAll() => _states.clear();
}
