enum PrayerPosition {
  niyat,
  takbiriTahrima,
  qiyom,
  qiroat,
  ruku,
  qavma,
  sajda,
  jalsa,
  qadaiUla,
  qadaiOxira,
  salam,
  prayerEnd,
}

extension PrayerPositionLabel on PrayerPosition {
  String get label {
    switch (this) {
      case PrayerPosition.niyat: return 'Niyat';
      case PrayerPosition.takbiriTahrima: return 'Takbiri tahrima';
      case PrayerPosition.qiyom: return 'Qiyom';
      case PrayerPosition.qiroat: return 'Qiroat';
      case PrayerPosition.ruku: return 'Ruku’';
      case PrayerPosition.qavma: return 'Qavma';
      case PrayerPosition.sajda: return 'Sajda';
      case PrayerPosition.jalsa: return 'Jalsa';
      case PrayerPosition.qadaiUla: return 'Birinchi qa’da';
      case PrayerPosition.qadaiOxira: return 'Oxirgi qa’da';
      case PrayerPosition.salam: return 'Salom';
      case PrayerPosition.prayerEnd: return 'Namoz tugashi';
    }
  }
}
