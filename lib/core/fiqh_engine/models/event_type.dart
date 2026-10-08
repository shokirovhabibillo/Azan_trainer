enum EventType {
  qiroatOmitted,
  zamSuraAdded,
  fatihaRepeated,
  qiroatDelayed,
  wrongSurahOrder,
  sameSurahRepeated,
  jahrInsteadOfSirr,
  sirrInsteadOfJahr,
  rukuRepeated,
  sajdaRepeated,
  extraRakat,
  firstQaidaOmitted,
  actionDoubt,
  rakatDoubt,
  externalMovement,
  zamSuraOmitted,
  qunutOmitted,
}

extension EventTypeLabel on EventType {
  String get label {
    switch (this) {
      case EventType.qiroatOmitted: return 'Fotiha/qiroat qoldirildi';
      case EventType.zamSuraAdded: return 'Zam sura qo‘shib o‘qildi';
      case EventType.fatihaRepeated: return 'Fotiha takrorlandi';
      case EventType.qiroatDelayed: return 'Qiroat 3 tasbih miqdoridan ortiq kechikdi';
      case EventType.wrongSurahOrder: return 'Sura tartibi adashdi';
      case EventType.sameSurahRepeated: return 'Bir sura ikki rak’atda takrorlandi';
      case EventType.jahrInsteadOfSirr: return 'Jahr o‘rniga sirr qilindi';
      case EventType.sirrInsteadOfJahr: return 'Sirr o‘rniga jahr qilindi';
      case EventType.rukuRepeated: return 'Ruku’ takrorlandi';
      case EventType.sajdaRepeated: return 'Sajda takrorlandi';
      case EventType.extraRakat: return 'Ortiqcha rak’at qilindi';
      case EventType.firstQaidaOmitted: return 'Birinchi qa’da qoldirildi';
      case EventType.actionDoubt: return 'Amal bo‘yicha shubha';
      case EventType.rakatDoubt: return 'Rak’at sonida shubha';
      case EventType.externalMovement: return 'Tashqi/ortiqcha harakat';
      case EventType.zamSuraOmitted: return 'Zam sura qoldirildi';
      case EventType.qunutOmitted: return 'Qunut qoldirildi';
    }
  }
}
