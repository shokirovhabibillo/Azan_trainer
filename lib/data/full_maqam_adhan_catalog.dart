import '../models/maqam.dart';

/// v1.17: TO'LIQ, uzluksiz azon namunasi — foydalanuvchi maqomni
/// tanlashdan oldin "eshitib tanishishi" uchun.
///
/// MUHIM — QAT'IY AJRATISH: bu klass va uni ishlatuvchi
/// [FullMaqamAdhanCatalog] — [MaqamReferenceCatalog] (jumla-darajasidagi,
/// pitch/duration tahlili uchun) bilan HECH QANDAY aloqasi yo'q, va
/// hech qachon bo'lmaydi:
///   - YIN pitch detector'ga berilmaydi
///   - PitchContourExtractor'ga berilmaydi
///   - ReferencePitchComparator'ga berilmaydi
///   - DurationAnalyzer'ga berilmaydi
///   - Phrase yoki foydalanuvchi recordingi bilan solishtirilmaydi
///
/// Bu — FAQAT `AudioPlayerService.playAsset()` orqali oddiy
/// Play/Pause/Stop uchun ishlatiladi (xuddi reference audio "eshitish"
/// tugmasi kabi, lekin butun azon davomida).
class FullMaqamAdhanReference {
  final Maqam maqam;
  final String audioFile;

  const FullMaqamAdhanReference({
    required this.maqam,
    required this.audioFile,
  });
}

/// v1.17: 8 ta maqom uchun to'liq, uzluksiz azon yozuvlari xaritasi.
/// Fayllar (mavjud bo'lganda) `assets/audio/maqamat/full/` papkasida
/// joylashadi.
///
/// v1.18 — MUHIM O'ZGARISH: ilova hajmini kichraytirish uchun
/// (467MB -> 273MB), bu fayllar ONGLI RAVISHDA olib tashlandi. Shu
/// sababli `all` ro'yxati hozircha BO'SH — `audioFileFor()` har doim
/// `null` qaytaradi, va `FullAdhanPreviewScreen` avtomatik ravishda
/// jumla-darajasidagi fayllarni ketma-ket ijro etish rejimiga
/// o'tadi (`SequentialPlaybackSequence` orqali — hech qanday yangi
/// fayl yaratilmaydi).
///
/// Kelajakda katta hajmli (467MB) versiya tayyorlanganda, shu
/// ro'yxatga yozuvlar qaytarilishi kifoya — boshqa hech qanday kod
/// o'zgarishi shart emas (`FullAdhanPreviewScreen` ikkala holatni ham
/// avtomatik qo'llab-quvvatlaydi).
class FullMaqamAdhanCatalog {
  FullMaqamAdhanCatalog._();

  static const List<FullMaqamAdhanReference> all = [];

  /// Berilgan maqom uchun to'liq audio faylini qaytaradi, agar mavjud
  /// bo'lmasa `null` (soxta bilan to'ldirilmaydi — UI "hali mavjud
  /// emas" deb ko'rsatadi).
  static String? audioFileFor(Maqam maqam) {
    for (final ref in all) {
      if (ref.maqam == maqam) return ref.audioFile;
    }
    return null;
  }
}
