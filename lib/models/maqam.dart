/// Arab/o'zbek azon an'analarida ishlatiladigan maqom turlari.
///
/// MUHIM: bu ro'yxat faqat mumkin bo'lgan qiymatlarni belgilaydi — hech
/// qanday reference audio uchun maqom "taxmin qilib" to'ldirilmaydi.
/// Agar audio faylning maqomi hali tasdiqlanmagan bo'lsa,
/// [Maqam.unknown] ishlatiladi (bu — v1.3'dagi barcha katalog
/// yozuvlari uchun amaldagi holat, chunki hech qanday reference audio
/// hali qo'shilmagan).
enum Maqam {
  bayati,
  nahawand,
  ajam,
  hijaz,
  rast,
  kurd,
  saba,
  sikah,

  /// Maqom hali tasdiqlanmagan/aniqlanmagan.
  unknown,
}

extension MaqamLabel on Maqam {
  /// Foydalanuvchiga ko'rsatiladigan qisqa nom, masalan "Bayati" yoki
  /// "unknown" (aniq shu so'z bilan — talab: "maqam: unknown").
  String get label {
    switch (this) {
      case Maqam.bayati:
        return 'Bayati';
      case Maqam.nahawand:
        return 'Nahawand';
      case Maqam.ajam:
        return 'Ajam';
      case Maqam.hijaz:
        return 'Hijaz';
      case Maqam.rast:
        return 'Rast';
      case Maqam.kurd:
        return 'Kurd';
      case Maqam.saba:
        return 'Saba';
      case Maqam.sikah:
        return 'Sikah';
      case Maqam.unknown:
        return 'unknown';
    }
  }
}
