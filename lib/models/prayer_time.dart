/// v1.17: Azon mashqidan oldingi namoz vaqti tanlovi.
///
/// MUHIM: hozircha bu FAQAT navigatsion — barcha 4 namoz uchun bir
/// xil Azon kontenti ishlatiladi (Hanafiy amaliyotda Azon matni
/// namoz vaqtiga qarab o'zgarmaydi). Lekin bu qiymat kelajakda har
/// bir namoz uchun alohida konfiguratsiya/reference qo'shish imkonini
/// saqlab qolish uchun modelda tutiladi.
enum PrayerTime { peshin, asr, shom, xufton }

extension PrayerTimeLabel on PrayerTime {
  String get label {
    switch (this) {
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
}
