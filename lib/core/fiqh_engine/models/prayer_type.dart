enum PrayerType { bomdod, peshin, asr, shom, xufton, vitr, juma, taroveh, sunnat, nafl }

extension PrayerTypeLabel on PrayerType {
  String get label {
    switch (this) {
      case PrayerType.bomdod: return 'Bomdod';
      case PrayerType.peshin: return 'Peshin';
      case PrayerType.asr: return 'Asr';
      case PrayerType.shom: return 'Shom';
      case PrayerType.xufton: return 'Xufton';
      case PrayerType.vitr: return 'Vitr';
      case PrayerType.juma: return 'Juma';
      case PrayerType.taroveh: return 'Taroveh';
      case PrayerType.sunnat: return 'Sunnat';
      case PrayerType.nafl: return 'Nafl';
    }
  }
}
