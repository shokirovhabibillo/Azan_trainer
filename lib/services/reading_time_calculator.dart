/// v1.13: matn uzunligiga qarab minimal o'qish vaqtini hisoblaydi.
///
/// Maqsad — foydalanuvchini "jazolash" emas, balki o'rtacha inson
/// o'qish tezligiga mos, tabiiy vaqt berish (talab: juda qisqa matn
/// uchun ham minimal chegara, lekin bezovta qiladigan darajada
/// bo'lmasin).
class ReadingTimeCalculator {
  ReadingTimeCalculator._();

  /// O'rtacha o'qish tezligi (so'z/daqiqa). Rasmiy/diniy matn uchun
  /// odatiy tezlikdan biroz sekinroq, lekin haddan tashqari sekin
  /// emas.
  static const int wordsPerMinute = 220;

  /// Har qanday, hatto juda qisqa matn uchun ham shu qadar vaqt
  /// beriladi.
  static const int minimumSeconds = 6;

  static Duration forText(String text) {
    final wordCount = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final computedSeconds = (wordCount / wordsPerMinute * 60).round();
    final seconds =
        computedSeconds < minimumSeconds ? minimumSeconds : computedSeconds;
    return Duration(seconds: seconds);
  }
}
