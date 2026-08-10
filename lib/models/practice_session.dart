import 'analysis_result.dart';

/// Bitta mashq sessiyasi: qaysi jumla, qayerga yozildi, natija qanday.
class PracticeSession {
  final String phraseId;
  final String recordingPath;
  final DateTime timestamp;
  final AnalysisResult? result;

  const PracticeSession({
    required this.phraseId,
    required this.recordingPath,
    required this.timestamp,
    this.result,
  });

  Map<String, dynamic> toJson() => {
        'phraseId': phraseId,
        'recordingPath': recordingPath,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      phraseId: json['phraseId'] as String,
      recordingPath: json['recordingPath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
