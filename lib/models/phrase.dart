import 'maqam.dart';

enum PhraseCategory { azon, bomdodQoshimcha, iqomat }

/// Bitta mashq qilinadigan jumla (masalan, "Allohu akbar").
class Phrase {
  final String id;
  final PhraseCategory category;
  final String arabicText;
  final String transliteration;
  final String meaningUz;

  /// Jumla necha marta takrorlanishi kerak (masalan, Bomdodda
  /// "As-solaatu khoyrum minan-navm" 2 marta aytiladi).
  final int repeatCount;

  /// assets/audio/ ichidagi fayl nomi. Fayl hali qo'shilmagan bo'lishi
  /// mumkin — bu holatda UI "Reference audio mavjud emas" deb ko'rsatadi,
  /// hech qanday fake audio bilan almashtirilmaydi.
  final String referenceAudioFile;

  /// Reference audio qaysi maqomda o'qilgani (metadata).
  ///
  /// MUHIM: default qiymat [Maqam.unknown] — chunki hozircha hech
  /// qanday reference audio fayli mavjud emas, demak uning maqomi ham
  /// tasdiqlanmagan. Bu qiymat taxmin qilib to'ldirilmaydi; faqat
  /// haqiqiy audio tahlil qilingandan keyin aniq maqom bilan
  /// yangilanishi kerak.
  final Maqam maqam;

  const Phrase({
    required this.id,
    required this.category,
    required this.arabicText,
    required this.transliteration,
    required this.meaningUz,
    required this.referenceAudioFile,
    this.repeatCount = 1,
    this.maqam = Maqam.unknown,
  });

  /// v1.10: foydalanuvchi bir nechta maqom variantidan birini
  /// tanlaganda ishlatiladi. `PitchAnalyzer`/`DurationAnalyzer`
  /// (himoyalangan fayllar) o'zgarishsiz qoladi — ular oddiy `Phrase`
  /// obyektini qabul qiladi; biz shunchaki BOSHQA `referenceAudioFile`/
  /// `maqam` qiymatlariga ega yangi `Phrase` nusxasini hosil qilib,
  /// o'shani beramiz.
  Phrase copyWithReference({
    required String referenceAudioFile,
    required Maqam maqam,
  }) {
    return Phrase(
      id: id,
      category: category,
      arabicText: arabicText,
      transliteration: transliteration,
      meaningUz: meaningUz,
      referenceAudioFile: referenceAudioFile,
      repeatCount: repeatCount,
      maqam: maqam,
    );
  }
}
