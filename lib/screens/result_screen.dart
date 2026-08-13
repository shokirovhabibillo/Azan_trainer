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
import '../widgets/pitch_deviation_chart.dart';
import '../widgets/pitch_overlay_chart.dart';
import '../widgets/pitch_piano_roll_chart.dart';

class ResultScreen extends StatefulWidget {
  final Phrase phrase;
  final String recordingPath;
  final VoidCallback onRetry;

  /// v1.7: agar bu jumla uchun tahlil oldin allaqachon hisoblangan
  /// bo'lsa (masalan, foydalanuvchi boshqa jumlaga o'tib qaytgan
  /// bo'lsa), keshlangan natija shu yerdan uzatiladi — tahlil QAYTA
  /// hisoblanmaydi (PitchAnalyzer/DurationAnalyzer chaqirilmaydi).
  final AnalysisResult? cachedResult;
  final DurationComparisonResult? cachedDurationResult;

  /// v1.7: tahlil YANGIDAN hisoblanganda (keshlanmagan holatda),
  /// natija shu callback orqali chaqiruvchiga (PhrasePracticeScreen)
  /// qaytariladi — u buni PracticeSessionController'ga saqlaydi.
  final void Function(
    AnalysisResult result,
    DurationComparisonResult durationResult,
  )? onAnalysisComputed;

  const ResultScreen({
    super.key,
    required this.phrase,
    required this.recordingPath,
    required this.onRetry,
    this.cachedResult,
    this.cachedDurationResult,
    this.onAnalysisComputed,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

enum _ChartType { line, deviation, pianoRoll, overlay }

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

  /// v1.10: foydalanuvchi tanlagan grafik turi (talab: "foydalanuvchi
  /// o'zi qulayini tanlab foydalansin"). Faqat taqdimot holati —
  /// tahlil natijasiga ta'sir qilmaydi.
  _ChartType _chartType = _ChartType.line;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    // v1.7: agar keshlangan natija bergan bo'lsak, PitchAnalyzer/
    // DurationAnalyzer'ni umuman chaqirmasdan, to'g'ridan-to'g'ri
    // shuni ko'rsatamiz — tahlil algoritmi qayta ishlamaydi.
    if (widget.cachedResult != null && widget.cachedDurationResult != null) {
      setState(() {
        _result = widget.cachedResult;
        _durationResult = widget.cachedDurationResult;
        _loading = false;
      });
      return;
    }

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
    // v1.7: yangi hisoblangan natijani chaqiruvchiga qaytaramiz, u
    // buni saqlab qo'yadi — keyingi safar shu jumlaga qaytilganda
    // qayta hisoblanmaydi.
    widget.onAnalysisComputed?.call(result, durationResult);
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
                  _buildChartTypeSelector(),
                  const SizedBox(height: 10),
                  _buildSelectedChart(result),
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

  Widget _buildChartTypeSelector() {
    final hasReference = _result?.referenceComparison.isAvailable ?? false;

    Widget chip(_ChartType type, String label) {
      // "Farq" va "Qoplama" grafiklari reference talab qiladi.
      final requiresReference =
          type == _ChartType.deviation || type == _ChartType.overlay;
      final enabled = !requiresReference || hasReference;
      return ChoiceChip(
        label: Text(label),
        selected: _chartType == type,
        onSelected: enabled
            ? (_) => setState(() => _chartType = type)
            : null,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(_ChartType.line, 'Chiziq'),
        chip(_ChartType.pianoRoll, 'Piano-roll'),
        chip(_ChartType.deviation, 'Farq'),
        chip(_ChartType.overlay, 'Qoplama'),
      ],
    );
  }

  Widget _buildSelectedChart(AnalysisResult result) {
    final hasReference = result.referenceComparison.isAvailable;
    final userFrames = result.pitchContour;
    final userDuration = result.recordingDurationSeconds ?? 0;
    final refFrames =
        hasReference ? result.referenceComparison.referenceContour : null;
    final refDuration =
        hasReference ? result.referenceComparison.referenceDurationSeconds : null;

    switch (_chartType) {
      case _ChartType.line:
        return DualPitchContourChart(
          userFrames: userFrames,
          userDurationSeconds: userDuration,
          referenceFrames: refFrames,
          referenceDurationSeconds: refDuration,
        );
      case _ChartType.pianoRoll:
        return PitchPianoRollChart(
          userFrames: userFrames,
          userDurationSeconds: userDuration,
          referenceFrames: refFrames,
          referenceDurationSeconds: refDuration,
        );
      case _ChartType.deviation:
        if (!hasReference || refFrames == null || refDuration == null) {
          return const Text(
            'Farq grafigi uchun reference audio kerak.',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          );
        }
        return PitchDeviationChart(
          userFrames: userFrames,
          userDurationSeconds: userDuration,
          referenceFrames: refFrames,
          referenceDurationSeconds: refDuration,
        );
      case _ChartType.overlay:
        if (!hasReference || refFrames == null || refDuration == null) {
          return const Text(
            'Qoplama grafigi uchun reference audio kerak.',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          );
        }
        return PitchOverlayChart(
          userFrames: userFrames,
          userDurationSeconds: userDuration,
          referenceFrames: refFrames,
          referenceDurationSeconds: refDuration,
        );
    }
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
