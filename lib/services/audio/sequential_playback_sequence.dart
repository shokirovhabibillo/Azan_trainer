/// v1.18: bir nechta audio faylni JISMONAN birlashtirmasdan, birin-
/// ketin avtomatik ijro etish uchun sof holat-mashinasi.
///
/// Bu — "to'liq azon" hissini berish uchun ishlatiladi: haqiqiy
/// uzluksiz yozuv o'rniga, mavjud jumla-darajasidagi fayllar
/// (`MaqamReferenceCatalog`dan) to'g'ri tartibda, bittasi tugagach
/// ikkinchisi avtomatik boshlanadigan qilib ijro etiladi — yangi fayl
/// yaratilmaydi, hech qanday qo'shimcha xotira sarflanmaydi.
class SequentialPlaybackSequence {
  final List<String> audioFiles;
  int _index = 0;

  SequentialPlaybackSequence(this.audioFiles);

  bool get isEmpty => audioFiles.isEmpty;

  /// Joriy ijro etilishi kerak bo'lgan fayl, yoki `null` (ketma-ketlik
  /// boshlanmagan yoki allaqachon tugagan bo'lsa).
  String? get current =>
      (_index >= 0 && _index < audioFiles.length) ? audioFiles[_index] : null;

  int get currentIndex => _index;

  bool get isFinished => _index >= audioFiles.length;

  /// Ketma-ketlikni boshidan boshlaydi va birinchi faylni qaytaradi.
  String? start() {
    _index = 0;
    return current;
  }

  /// Keyingi faylga o'tadi. Agar ketma-ketlik tugagan bo'lsa, `null`
  /// qaytaradi.
  String? advance() {
    _index++;
    return current;
  }

  void reset() {
    _index = 0;
  }
}
