import '../models/maqam.dart';

/// v1.10: ba'zi jumlalar uchun BIR NECHTA maqomda yozib olingan
/// reference audio mavjud (masalan, Azonning 6 jumlasi — Bayati,
/// Lami, Kurd). Foydalanuvchi ular orasidan tanlab, tahlilni shu
/// tanlangan maqom asosida o'tkazishi mumkin.
///
/// MUHIM: `Phrase.referenceAudioFile`/`Phrase.maqam` (asosiy katalogda,
/// `phrase_catalog.dart`da) — bu "standart" (birinchi/asosiy) variant
/// bo'lib qolaveradi. Bu xarita FAQAT qo'shimcha variantlarni beradi;
/// standart variant har doim shu yerda ham takrorlanadi (ro'yxatning
/// birinchi elementi sifatida), shunda UI barcha variantlarni bir xil
/// tarzda ko'rsata oladi.
class MaqamReferenceCatalog {
  MaqamReferenceCatalog._();

  /// jumla ID -> shu jumla uchun mavjud barcha (maqom, audio fayl)
  /// juftliklari. Faqat bir nechta variant mavjud bo'lgan jumlalar
  /// shu yerda ro'yxatlangan — qolganlari uchun UI faqat standart
  /// (`Phrase.referenceAudioFile`) variantni ko'rsatadi.
  static const Map<String, List<MaqamVariant>> variants = {
    'azon_allohu_akbar': [
      MaqamVariant(maqam: Maqam.bayati, audioFile: 'azon_allohu_akbar.wav'),
      MaqamVariant(
        maqam: Maqam.lami,
        audioFile: 'azon_allohu_akbar_lami.wav',
      ),
      MaqamVariant(
        maqam: Maqam.kurd,
        audioFile: 'azon_allohu_akbar_kurd.wav',
      ),
      MaqamVariant(
        maqam: Maqam.hijaz,
        audioFile: 'azon_allohu_akbar_hijaz.wav',
      ),
    ],
    'azon_ashhadu_laa_ilaaha': [
      MaqamVariant(
        maqam: Maqam.bayati,
        audioFile: 'azon_ashhadu_laa_ilaaha.wav',
      ),
      MaqamVariant(
        maqam: Maqam.lami,
        audioFile: 'azon_ashhadu_laa_ilaaha_lami.wav',
      ),
      MaqamVariant(
        maqam: Maqam.kurd,
        audioFile: 'azon_ashhadu_laa_ilaaha_kurd.wav',
      ),
      MaqamVariant(
        maqam: Maqam.hijaz,
        audioFile: 'azon_ashhadu_laa_ilaaha_hijaz.wav',
      ),
    ],
    'azon_ashhadu_anna_muhammadan': [
      MaqamVariant(
        maqam: Maqam.bayati,
        audioFile: 'azon_ashhadu_anna_muhammadan.wav',
      ),
      MaqamVariant(
        maqam: Maqam.lami,
        audioFile: 'azon_ashhadu_anna_muhammadan_lami.wav',
      ),
      MaqamVariant(
        maqam: Maqam.kurd,
        audioFile: 'azon_ashhadu_anna_muhammadan_kurd.wav',
      ),
      MaqamVariant(
        maqam: Maqam.hijaz,
        audioFile: 'azon_ashhadu_anna_muhammadan_hijaz.wav',
      ),
    ],
    'azon_hayya_alas_solah': [
      MaqamVariant(
        maqam: Maqam.bayati,
        audioFile: 'azon_hayya_alas_solah.wav',
      ),
      MaqamVariant(
        maqam: Maqam.lami,
        audioFile: 'azon_hayya_alas_solah_lami.wav',
      ),
      MaqamVariant(
        maqam: Maqam.kurd,
        audioFile: 'azon_hayya_alas_solah_kurd.wav',
      ),
      MaqamVariant(
        maqam: Maqam.hijaz,
        audioFile: 'azon_hayya_alas_solah_hijaz.wav',
      ),
    ],
    'azon_hayya_alal_falah': [
      MaqamVariant(
        maqam: Maqam.bayati,
        audioFile: 'azon_hayya_alal_falah.wav',
      ),
      MaqamVariant(
        maqam: Maqam.lami,
        audioFile: 'azon_hayya_alal_falah_lami.wav',
      ),
      MaqamVariant(
        maqam: Maqam.kurd,
        audioFile: 'azon_hayya_alal_falah_kurd.wav',
      ),
      MaqamVariant(
        maqam: Maqam.hijaz,
        audioFile: 'azon_hayya_alal_falah_hijaz.wav',
      ),
    ],
    'azon_allohu_akbar_closing': [
      MaqamVariant(
        maqam: Maqam.bayati,
        audioFile: 'azon_allohu_akbar_closing.wav',
      ),
      MaqamVariant(
        maqam: Maqam.lami,
        audioFile: 'azon_allohu_akbar_closing_lami.wav',
      ),
      MaqamVariant(
        maqam: Maqam.kurd,
        audioFile: 'azon_allohu_akbar_closing_kurd.wav',
      ),
      MaqamVariant(
        maqam: Maqam.hijaz,
        audioFile: 'azon_allohu_akbar_closing_hijaz.wav',
      ),
    ],
    // MUHIM: "azon_laa_ilaaha_illalloh" uchun Lami/Kurd variantlari
    // hali YO'Q — foydalanuvchi bergan ikkala audio yozuvda ham bu
    // jumlaga mos alohida segment aniqlanmadi (pastga, README'ga
    // qarang). Shuning uchun bu jumla shu xaritada YO'Q — UI faqat
    // standart (Bayati) variantni ko'rsatadi.
  };

  /// Berilgan jumla uchun mavjud barcha variantlarni qaytaradi (agar
  /// bo'lmasa — bo'sh ro'yxat).
  static List<MaqamVariant> variantsFor(String phraseId) =>
      variants[phraseId] ?? const [];

  static bool hasMultipleVariants(String phraseId) =>
      variantsFor(phraseId).length > 1;
}

class MaqamVariant {
  final Maqam maqam;
  final String audioFile;

  const MaqamVariant({required this.maqam, required this.audioFile});
}
