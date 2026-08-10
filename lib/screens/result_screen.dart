import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../models/duration_comparison_result.dart';
import '../models/phrase.dart';
import '../models/reference_comparison_result.dart';
import '../services/analysis/audio_analyzer.dart';
import '../services/analysis/duration_analyzer.dart';
import '../services/analysis/pitch_analyzer.dart';
import '../widgets/dual_pitch_contour_chart.dart';
import '../widgets/metric_tile.dart';

class ResultScreen extends StatefulWidget {
  final Phrase phrase;
  final String recordingPath;
  final VoidCallback onRetry;

  const ResultScreen({
    super.key,
    required this.phrase,
    required this.recordingPath,
    required this.onRetry,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // v1.1: haqiqiy F0/pitch tahlili. v1.2: reference mavjud bo'lganda
  // shu tahlilchi orqali reference bilan taqqoslash ham amalga oshadi.
  final AudioAnalyzer _analyzer = PitchAnalyzer();

  // v1.4: Duration/mad tahlili — PitchAnalyzer'dan MUSTAQIL, alohida
  // chaqiriladi. Ikkisi bir-biriga bog'lanmagan; natijalar faqat shu
  // ekranda ko'rsatish uchun birlashtiriladi.
  final DurationAnalyzer _durationAnalyzer = const DurationAnalyzer();

  AnalysisResult? _result;
  DurationComparisonResult? _durationResult;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final pitchFuture = _analyzer.analyze(
      recordingPath: widget.recordingPath,
      referencePhrase: widget.phrase,
    );
    final durationFuture = _durationAnalyzer.analyze(
      recordingPath: widget.recordingPath,
      referencePhrase: widget.phrase,
    );

    final result = await pitchFuture;
    final durationResult = await durationFuture;

    if (!mounted) return;
    setState(() {
      _result = result;
      _durationResult = durationResult;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Natija')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildResult(),
    );
  }

  Widget _buildResult() {
    final result = _result!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.phrase.transliteration,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              MetricTile(metric: result.pitch),
              const Divider(height: 1),
              MetricTile(metric: result.duration),
            ],
          ),
        ),
        if (result.pitchContour.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pitch contour',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  DualPitchContourChart(
                    userFrames: result.pitchContour,
                    userDurationSeconds: result.recordingDurationSeconds ?? 0,
                    referenceFrames:
                        result.referenceComparison.isAvailable
                            ? result.referenceComparison.referenceContour
                            : null,
                    referenceDurationSeconds:
                        result.referenceComparison.isAvailable
                            ? result.referenceComparison
                                .referenceDurationSeconds
                            : null,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _ReferenceComparisonCard(comparison: result.referenceComparison),
        const SizedBox(height: 16),
        if (_durationResult != null) _DurationCard(result: _durationResult!),
        const SizedBox(height: 20),
        Card(
          color: result.isFullyConnected ? null : Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  result.isFullyConnected
                      ? Icons.flag
                      : Icons.info_outline,
                  color: result.isFullyConnected
                      ? Colors.deepOrange
                      : Colors.amber.shade800,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.topIssue ??
                        (result.isFullyConnected
                            ? 'Xato topilmadi — ajoyib!'
                            : 'Tahlil moduli hali ulanmagan. Recording '
                                'saqlandi, lekin pitch/duration bahosi '
                                'keyingi bosqichda qo\'shiladi.'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: widget.onRetry,
          icon: const Icon(Icons.mic),
          label: const Text('Qayta aytish'),
        ),
      ],
    );
  }
}

class _ReferenceComparisonCard extends StatelessWidget {
  final ReferenceComparisonResult comparison;

  const _ReferenceComparisonCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final isAvailable = comparison.isAvailable;
    return Card(
      color: isAvailable ? null : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.compare_arrows : Icons.link_off,
                  color: isAvailable ? Colors.teal : Colors.black45,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Reference bilan taqqoslash',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comparison.message),
            if (isAvailable) ...[
              const SizedBox(height: 12),
              if (comparison.meanPitchDifferenceSemitones != null)
                _StatRow(
                  label: 'O\'rtacha pitch farqi',
                  value:
                      '${comparison.meanPitchDifferenceSemitones!.toStringAsFixed(1)} '
                      'semiton (${(comparison.meanPitchDifferenceSemitones! * 100).round()} cent)',
                ),
              if (comparison.contourSimilarity != null)
                _StatRow(
                  label: 'Contour o\'xshashligi',
                  value:
                      '${(comparison.contourSimilarity! * 100).round()}% '
                      '(shakl bo\'yicha korrelyatsiya)',
                ),
              if (comparison.userDurationSeconds != null &&
                  comparison.referenceDurationSeconds != null)
                _StatRow(
                  label: 'Davomiylik (siz / reference)',
                  value:
                      '${comparison.userDurationSeconds!.toStringAsFixed(1)}s / '
                      '${comparison.referenceDurationSeconds!.toStringAsFixed(1)}s',
                ),
              if (comparison.userVoicedRatio != null &&
                  comparison.referenceVoicedRatio != null)
                _StatRow(
                  label: 'Ovozli ulush (siz / reference)',
                  value:
                      '${(comparison.userVoicedRatio! * 100).round()}% / '
                      '${(comparison.referenceVoicedRatio! * 100).round()}%',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final DurationComparisonResult result;

  const _DurationCard({required this.result});

  String _fmtMs(double? ms) {
    if (ms == null) return '—';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  @override
  Widget build(BuildContext context) {
    final available = result.available;
    return Card(
      color: available ? null : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  available ? Icons.timer_outlined : Icons.timer_off_outlined,
                  color: available ? Colors.indigo : Colors.black45,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Duration',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!available) ...[
              const Text('Reference duration mavjud emas'),
              const SizedBox(height: 4),
              Text(
                result.feedback,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (result.userActiveDurationMs != null) ...[
                const SizedBox(height: 8),
                _StatRow(
                  label: 'User (faol qism)',
                  value: _fmtMs(result.userActiveDurationMs),
                ),
              ],
            ] else ...[
              _StatRow(
                label: 'User',
                value: _fmtMs(result.userActiveDurationMs),
              ),
              _StatRow(
                label: 'Reference',
                value: _fmtMs(result.referenceActiveDurationMs),
              ),
              _StatRow(
                label: 'Farq',
                value:
                    '${result.durationDifferenceMs! >= 0 ? '+' : ''}'
                    '${_fmtMs(result.durationDifferenceMs)}',
              ),
              const SizedBox(height: 8),
              Text(
                result.feedback,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}
