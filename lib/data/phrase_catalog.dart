import '../models/maqam.dart';
import '../models/phrase.dart';

/// MVP v1 uchun boshlang'ich jumlalar katalogi.
/// Kelajakda to'liq azon matni va maqom variantlari bilan kengaytiriladi.
class PhraseCatalog {
  PhraseCatalog._();

  static const List<Phrase> azon = [
    Phrase(
      id: 'azon_allohu_akbar',
      category: PhraseCategory.azon,
      arabicText: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allohu akbar',
      meaningUz: "Alloh Buyukdir",
      referenceAudioFile: 'azon_allohu_akbar.wav',
      repeatCount: 4,
      // Maqom hozircha tasdiqlanmagan — taxmin qilinmaydi.
      maqam: Maqam.unknown,
    ),
    Phrase(
      id: 'azon_ashhadu_laa_ilaaha',
      category: PhraseCategory.azon,
      arabicText: 'أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ',
      transliteration: 'Ashhadu an laa ilaaha illalloh',
      meaningUz: "Guvohlik beramanki, Allohdan o'zga iloh yo'q",
      referenceAudioFile: 'azon_ashhadu_laa_ilaaha.wav',
      repeatCount: 2,
      // Maqom hozircha tasdiqlanmagan — taxmin qilinmaydi.
      maqam: Maqam.unknown,
    ),
    Phrase(
      id: 'azon_ashhadu_anna_muhammadan',
      category: PhraseCategory.azon,
      arabicText: 'أَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ',
      transliteration: 'Ashhadu anna Muhammadar rosulullohi',
      meaningUz: "Guvohlik beramanki, Muhammad Allohning rasulidir",
      referenceAudioFile: 'azon_ashhadu_anna_muhammadan.wav',
      repeatCount: 2,
      // Maqom hozircha tasdiqlanmagan — taxmin qilinmaydi.
      maqam: Maqam.unknown,
    ),
    Phrase(
      id: 'azon_hayya_alas_solah',
      category: PhraseCategory.azon,
      arabicText: 'حَيَّ عَلَى الصَّلَاةِ',
      transliteration: 'Hayya alas-solaah',
      meaningUz: 'Namozga shoshiling',
      referenceAudioFile: 'azon_hayya_alas_solah.wav',
      repeatCount: 2,
      // Maqom hozircha tasdiqlanmagan — taxmin qilinmaydi.
      maqam: Maqam.unknown,
    ),
    Phrase(
      id: 'azon_hayya_alal_falah',
      category: PhraseCategory.azon,
      arabicText: 'حَيَّ عَلَى الْفَلَاحِ',
      transliteration: 'Hayya alal-falaah',
      meaningUz: 'Najotga shoshiling',
      referenceAudioFile: 'azon_hayya_alal_falah.wav',
      repeatCount: 2,
      // Maqom hozircha tasdiqlanmagan — taxmin qilinmaydi.
      maqam: Maqam.unknown,
    ),
    Phrase(
      id: 'azon_laa_ilaaha_illalloh',
      category: PhraseCategory.azon,
      arabicText: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      transliteration: 'Laa ilaaha illalloh',
      meaningUz: "Allohdan o'zga iloh yo'q",
      referenceAudioFile: 'azon_laa_ilaaha_illalloh.wav',
      repeatCount: 1,
      // Maqom hozircha tasdiqlanmagan — taxmin qilinmaydi.
      maqam: Maqam.unknown,
    ),
  ];

  /// Faqat Bomdod azonida, "Hayya alal-falah"dan keyin qo'shiladigan jumla.
  static const Phrase bomdodExtra = Phrase(
    id: 'bomdod_assolatu_khoyrum_minan_navm',
    category: PhraseCategory.bomdodQoshimcha,
    arabicText: 'الصَّلَاةُ خَيْرٌ مِنَ النَّوْمِ',
    transliteration: 'As-solaatu khoyrum minan-navm',
    meaningUz: "Namoz uyqudan afzaldir",
    referenceAudioFile: 'bomdod_assolatu_khoyrum_minan_navm.wav',
    repeatCount: 2,
    // Maqom hozircha tasdiqlanmagan — taxmin qilinmaydi.
    maqam: Maqam.unknown,
  );

  static const List<Phrase> iqomat = [
    Phrase(
      id: 'iqomat_qad_qomatis_solah',
      category: PhraseCategory.iqomat,
      arabicText: 'قَدْ قَامَتِ الصَّلَاةُ',
      transliteration: 'Qad qoomatis-solaah',
      meaningUz: 'Namoz boshlandi',
      referenceAudioFile: 'iqomat_qad_qomatis_solah.wav',
      repeatCount: 2,
      // Maqom hozircha tasdiqlanmagan — taxmin qilinmaydi.
      maqam: Maqam.unknown,
    ),
  ];

  /// Azon rejimi uchun to'liq jumlalar ketma-ketligi.
  /// isBomdod=true bo'lsa, "Hayya alal-falah"dan keyin bomdodga xos
  /// jumla qo'shiladi (Hanafiy tartibiga mos).
  static List<Phrase> azonSequence({required bool isBomdod}) {
    final result = <Phrase>[];
    for (final phrase in azon) {
      result.add(phrase);
      if (isBomdod && phrase.id == 'azon_hayya_alal_falah') {
        result.add(bomdodExtra);
      }
    }
    return result;
  }

  static List<Phrase> get all => [...azon, bomdodExtra, ...iqomat];

  static Phrase byId(String id) => all.firstWhere((p) => p.id == id);
}
