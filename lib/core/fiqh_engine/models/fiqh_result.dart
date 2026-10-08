enum FiqhResultStatus {
  validContinue,
  validWithSajdaiSahv,
  actionRequired,
  prayerInvalid,
  repeatRequired,
  needsSourceVerification,
}

extension FiqhResultStatusLabel on FiqhResultStatus {
  String get label {
    switch (this) {
      case FiqhResultStatus.validContinue: return 'Davom etish mumkin';
      case FiqhResultStatus.validWithSajdaiSahv: return 'Sajdai sahv bilan';
      case FiqhResultStatus.actionRequired: return 'Amal qilish kerak';
      case FiqhResultStatus.prayerInvalid: return 'Namoz yaroqsiz';
      case FiqhResultStatus.repeatRequired: return 'Qayta o‘qish kerak';
      case FiqhResultStatus.needsSourceVerification: return 'Manba tekshiruvi kerak';
    }
  }
}

class FiqhResult {
  final FiqhResultStatus status;
  final bool sajdaiSahv;
  final bool repeatPrayer;
  final String explanation;
  final String? ruleId;
  final String? sourceName;

  const FiqhResult({
    required this.status,
    required this.sajdaiSahv,
    required this.repeatPrayer,
    required this.explanation,
    this.ruleId,
    this.sourceName,
  });
}
