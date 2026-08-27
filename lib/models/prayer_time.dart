/// v1.17: Azon mashqidan oldingi namoz vaqti tanlovi.
///
/// v1.22: Bomdod (Fajr) endi alohida Home rejimi emas — Azon
/// oqimidagi 5-namoz vaqti sifatida birlashtirildi. Kontent farqi
/// faqat shu: Bomdod tanlanganda qo'shimcha "As-solaatu khoyrum
/// minan-navm" jumlasi qo'shiladi (`PhraseCatalog.azonSequence(
/// isBomdod: true)`), qolgan 4 namoz uchun oddiy Azon ketma-ketligi
/// ishlatiladi.
enum PrayerTime { bomdod, peshin, asr, shom, xufton }

extension PrayerTimeLabel on PrayerTime {
  String get label {
    switch (this) {
      case PrayerTime.bomdod:
        return 'Bomdod';
      case PrayerTime.peshin:
        return 'Peshin';
      case PrayerTime.asr:
        return 'Asr';
      case PrayerTime.shom:
        return 'Shom';
      case PrayerTime.xufton:
        return 'Xufton';
    }
  }

  /// v1.22: faqat Bomdod (Fajr) uchun Azon ketma-ketligiga
  /// "As-solaatu khoyrum minan-navm" jumlasi qo'shiladi.
  bool get isBomdod => this == PrayerTime.bomdod;
}
