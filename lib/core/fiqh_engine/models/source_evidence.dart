enum SourceType { book, omi }

class SourceEvidence {
  final SourceType sourceType;
  final String sourceName;
  final String? section;
  final int? page;
  final bool verified;

  const SourceEvidence({
    required this.sourceType,
    required this.sourceName,
    this.section,
    this.page,
    required this.verified,
  });
}
