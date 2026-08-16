/// v1.13: Majburiy onboarding'dagi bitta kontent sahifasi.
///
/// Bu — sof ma'lumot modeli, UI yoki tahlil mantig'iga aloqasi yo'q.
class OnboardingPageContent {
  final String title;
  final String body;
  final int pageNumber;
  final int totalPages;

  /// Ixtiyoriy manba (masalan, fatvo) — bosiladigan link sifatida
  /// ko'rsatiladi.
  final String? sourceLabel;
  final String? sourceUrl;

  const OnboardingPageContent({
    required this.title,
    required this.body,
    required this.pageNumber,
    required this.totalPages,
    this.sourceLabel,
    this.sourceUrl,
  });
}
