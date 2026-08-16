import '../models/maqam.dart';

/// v1.17: ba'zi jumlalar uchun BIR NECHTA maqomda yozib olingan
/// reference audio mavjud. v1.17'dan boshlab bu — 8 ta maqomning
/// TO'LIQ to'plami (Bayati, Ajam, Kurd, Hijaz, Lami, Nahawand, Rast,
/// Saba), har biri Azonning barcha 7 jumlasi + Bomdod qo'shimchasi
/// uchun (jami 8 jumla).
///
/// MUHIM: bu — faqat JUMLA-DARAJASIDAGI (phrase-level) reference audio
/// — pitch/duration tahlili uchun. TO'LIQ (uzluksiz) azon eshitish
/// uchun butunlay ALOHIDA, mustaqil `FullMaqamAdhanCatalog` ishlatiladi
/// (`full_maqam_adhan_catalog.dart`) — ikkalasi bir-biriga ARALASHMAYDI.
///
/// Fayllar `assets/audio/maqamat/phrases/{maqom}/` papkalarida
/// joylashgan (v1.16'gacha ishlatilgan tekis, prefiksli nomlash
/// o'rniga — endi tartibli papka strukturasi).
///
/// `Phrase.referenceAudioFile`/`Phrase.maqam` (asosiy katalogda) —
/// standart (fallback) variant bo'lib qolaveradi (agar biror sabab
/// bilan bu xaritada yozuv topilmasa).
class MaqamReferenceCatalog {
  MaqamReferenceCatalog._();

  static const Map<String, List<MaqamVariant>> variants = {
    'azon_allohu_akbar': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'maqamat/phrases/bayati/allohu_akbar.wav'),
      MaqamVariant(maqam: Maqam.ajam, audioFile: 'maqamat/phrases/ajam/allohu_akbar.wav'),
      MaqamVariant(maqam: Maqam.kurd, audioFile: 'maqamat/phrases/kurd/allohu_akbar.wav'),
      MaqamVariant(maqam: Maqam.hijaz, audioFile: 'maqamat/phrases/hijaz/allohu_akbar.wav'),
      MaqamVariant(maqam: Maqam.lami, audioFile: 'maqamat/phrases/lami/allohu_akbar.wav'),
      MaqamVariant(maqam: Maqam.nahawand, audioFile: 'maqamat/phrases/nahawand/allohu_akbar.wav'),
      MaqamVariant(maqam: Maqam.rast, audioFile: 'maqamat/phrases/rast/allohu_akbar.wav'),
      MaqamVariant(maqam: Maqam.saba, audioFile: 'maqamat/phrases/saba/allohu_akbar.wav'),
    ],
    'azon_ashhadu_laa_ilaaha': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'maqamat/phrases/bayati/ashhadu_laa_ilaaha.wav'),
      MaqamVariant(maqam: Maqam.ajam, audioFile: 'maqamat/phrases/ajam/ashhadu_laa_ilaaha.wav'),
      MaqamVariant(maqam: Maqam.kurd, audioFile: 'maqamat/phrases/kurd/ashhadu_laa_ilaaha.wav'),
      MaqamVariant(maqam: Maqam.hijaz, audioFile: 'maqamat/phrases/hijaz/ashhadu_laa_ilaaha.wav'),
      MaqamVariant(maqam: Maqam.lami, audioFile: 'maqamat/phrases/lami/ashhadu_laa_ilaaha.wav'),
      MaqamVariant(maqam: Maqam.nahawand, audioFile: 'maqamat/phrases/nahawand/ashhadu_laa_ilaaha.wav'),
      MaqamVariant(maqam: Maqam.rast, audioFile: 'maqamat/phrases/rast/ashhadu_laa_ilaaha.wav'),
      MaqamVariant(maqam: Maqam.saba, audioFile: 'maqamat/phrases/saba/ashhadu_laa_ilaaha.wav'),
    ],
    'azon_ashhadu_anna_muhammadan': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'maqamat/phrases/bayati/ashhadu_anna_muhammadan.wav'),
      MaqamVariant(maqam: Maqam.ajam, audioFile: 'maqamat/phrases/ajam/ashhadu_anna_muhammadan.wav'),
      MaqamVariant(maqam: Maqam.kurd, audioFile: 'maqamat/phrases/kurd/ashhadu_anna_muhammadan.wav'),
      MaqamVariant(maqam: Maqam.hijaz, audioFile: 'maqamat/phrases/hijaz/ashhadu_anna_muhammadan.wav'),
      MaqamVariant(maqam: Maqam.lami, audioFile: 'maqamat/phrases/lami/ashhadu_anna_muhammadan.wav'),
      MaqamVariant(maqam: Maqam.nahawand, audioFile: 'maqamat/phrases/nahawand/ashhadu_anna_muhammadan.wav'),
      MaqamVariant(maqam: Maqam.rast, audioFile: 'maqamat/phrases/rast/ashhadu_anna_muhammadan.wav'),
      MaqamVariant(maqam: Maqam.saba, audioFile: 'maqamat/phrases/saba/ashhadu_anna_muhammadan.wav'),
    ],
    'azon_hayya_alas_solah': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'maqamat/phrases/bayati/hayya_alas_solah.wav'),
      MaqamVariant(maqam: Maqam.ajam, audioFile: 'maqamat/phrases/ajam/hayya_alas_solah.wav'),
      MaqamVariant(maqam: Maqam.kurd, audioFile: 'maqamat/phrases/kurd/hayya_alas_solah.wav'),
      MaqamVariant(maqam: Maqam.hijaz, audioFile: 'maqamat/phrases/hijaz/hayya_alas_solah.wav'),
      MaqamVariant(maqam: Maqam.lami, audioFile: 'maqamat/phrases/lami/hayya_alas_solah.wav'),
      MaqamVariant(maqam: Maqam.nahawand, audioFile: 'maqamat/phrases/nahawand/hayya_alas_solah.wav'),
      MaqamVariant(maqam: Maqam.rast, audioFile: 'maqamat/phrases/rast/hayya_alas_solah.wav'),
      MaqamVariant(maqam: Maqam.saba, audioFile: 'maqamat/phrases/saba/hayya_alas_solah.wav'),
    ],
    'azon_hayya_alal_falah': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'maqamat/phrases/bayati/hayya_alal_falah.wav'),
      MaqamVariant(maqam: Maqam.ajam, audioFile: 'maqamat/phrases/ajam/hayya_alal_falah.wav'),
      MaqamVariant(maqam: Maqam.kurd, audioFile: 'maqamat/phrases/kurd/hayya_alal_falah.wav'),
      MaqamVariant(maqam: Maqam.hijaz, audioFile: 'maqamat/phrases/hijaz/hayya_alal_falah.wav'),
      MaqamVariant(maqam: Maqam.lami, audioFile: 'maqamat/phrases/lami/hayya_alal_falah.wav'),
      MaqamVariant(maqam: Maqam.nahawand, audioFile: 'maqamat/phrases/nahawand/hayya_alal_falah.wav'),
      MaqamVariant(maqam: Maqam.rast, audioFile: 'maqamat/phrases/rast/hayya_alal_falah.wav'),
      MaqamVariant(maqam: Maqam.saba, audioFile: 'maqamat/phrases/saba/hayya_alal_falah.wav'),
    ],
    'azon_allohu_akbar_closing': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'maqamat/phrases/bayati/allohu_akbar_closing.wav'),
      MaqamVariant(maqam: Maqam.ajam, audioFile: 'maqamat/phrases/ajam/allohu_akbar_closing.wav'),
      MaqamVariant(maqam: Maqam.kurd, audioFile: 'maqamat/phrases/kurd/allohu_akbar_closing.wav'),
      MaqamVariant(maqam: Maqam.hijaz, audioFile: 'maqamat/phrases/hijaz/allohu_akbar_closing.wav'),
      MaqamVariant(maqam: Maqam.lami, audioFile: 'maqamat/phrases/lami/allohu_akbar_closing.wav'),
      MaqamVariant(maqam: Maqam.nahawand, audioFile: 'maqamat/phrases/nahawand/allohu_akbar_closing.wav'),
      MaqamVariant(maqam: Maqam.rast, audioFile: 'maqamat/phrases/rast/allohu_akbar_closing.wav'),
      MaqamVariant(maqam: Maqam.saba, audioFile: 'maqamat/phrases/saba/allohu_akbar_closing.wav'),
    ],
    'azon_laa_ilaaha_illalloh': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'maqamat/phrases/bayati/laa_ilaaha_illalloh.wav'),
      MaqamVariant(maqam: Maqam.ajam, audioFile: 'maqamat/phrases/ajam/laa_ilaaha_illalloh.wav'),
      MaqamVariant(maqam: Maqam.kurd, audioFile: 'maqamat/phrases/kurd/laa_ilaaha_illalloh.wav'),
      MaqamVariant(maqam: Maqam.hijaz, audioFile: 'maqamat/phrases/hijaz/laa_ilaaha_illalloh.wav'),
      MaqamVariant(maqam: Maqam.lami, audioFile: 'maqamat/phrases/lami/laa_ilaaha_illalloh.wav'),
      MaqamVariant(maqam: Maqam.nahawand, audioFile: 'maqamat/phrases/nahawand/laa_ilaaha_illalloh.wav'),
      MaqamVariant(maqam: Maqam.rast, audioFile: 'maqamat/phrases/rast/laa_ilaaha_illalloh.wav'),
      MaqamVariant(maqam: Maqam.saba, audioFile: 'maqamat/phrases/saba/laa_ilaaha_illalloh.wav'),
    ],
    'bomdod_assolatu_khoyrum_minan_navm': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'maqamat/phrases/bayati/as_solaatu_khayrun_minan_nawm.wav'),
      MaqamVariant(maqam: Maqam.ajam, audioFile: 'maqamat/phrases/ajam/as_solaatu_khayrun_minan_nawm.wav'),
      MaqamVariant(maqam: Maqam.kurd, audioFile: 'maqamat/phrases/kurd/as_solaatu_khayrun_minan_nawm.wav'),
      MaqamVariant(maqam: Maqam.hijaz, audioFile: 'maqamat/phrases/hijaz/as_solaatu_khayrun_minan_nawm.wav'),
      MaqamVariant(maqam: Maqam.lami, audioFile: 'maqamat/phrases/lami/as_solaatu_khayrun_minan_nawm.wav'),
      MaqamVariant(maqam: Maqam.nahawand, audioFile: 'maqamat/phrases/nahawand/as_solaatu_khayrun_minan_nawm.wav'),
      MaqamVariant(maqam: Maqam.rast, audioFile: 'maqamat/phrases/rast/as_solaatu_khayrun_minan_nawm.wav'),
      MaqamVariant(maqam: Maqam.saba, audioFile: 'maqamat/phrases/saba/as_solaatu_khayrun_minan_nawm.wav'),
    ],  };

  /// Berilgan jumla uchun mavjud barcha variantlarni qaytaradi (agar
  /// bo'lmasa — bo'sh ro'yxat).
  static List<MaqamVariant> variantsFor(String phraseId) =>
      variants[phraseId] ?? const [];

  static bool hasMultipleVariants(String phraseId) =>
      variantsFor(phraseId).length > 1;

  /// v1.17: berilgan jumla uchun, berilgan MAQOMGA mos audio faylini
  /// topadi (agar mavjud bo'lsa). Session-darajasidagi maqom
  /// tanlovini amalga oshirish uchun ishlatiladi.
  static MaqamVariant? variantForMaqam(String phraseId, Maqam maqam) {
    final list = variantsFor(phraseId);
    for (final v in list) {
      if (v.maqam == maqam) return v;
    }
    return null;
  }
}

class MaqamVariant {
  final Maqam maqam;
  final String audioFile;

  const MaqamVariant({required this.maqam, required this.audioFile});
}
