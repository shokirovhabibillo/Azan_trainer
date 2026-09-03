import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/maqam_reference_catalog.dart';
import '../models/analysis_result.dart';
import '../models/duration_comparison_result.dart';
import '../models/phrase.dart';
import '../models/pitch_frame.dart';
import '../models/reference_comparison_result.dart';
import '../services/analysis/audio_analyzer.dart';
import '../services/analysis/duration_analyzer.dart';
import '../services/analysis/pitch_analyzer.dart';
import '../widgets/maqom_contour_chart.dart';
import '../widgets/metric_tile.dart';

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

  /// v1.27: "Pitch contour" turlari (Chiziq/Piano-roll/Farq/Qoplama)
  /// olib tashlandi — o'rniga "To'liq namuna" va mashq ekranidagi
  /// BIR XIL uslub ("Pitch shakli" — maqom_contours.json'dan
  /// reference egri chizig'i + foydalanuvchi ovozi ustma-ust)
  /// ishlatiladi.
  static const _maqomsWithContourData = {
    'bayati', 'ajam', 'kurd', 'hijaz', 'lami', 'nahawand', 'rast', 'saba',
  };

  Future<MaqomData>? _maqomDataFuture;

  String? get _maqomContourPhraseId {
    final variant = MaqamReferenceCatalog.variantForMaqam(
      widget.phrase.id,
      widget.phrase.maqam,
    );
    if (variant == null) return null;
    return variant.audioFile.split('/').last.replaceAll('.wav', '');
  }

  /// v1.27: yakunlangan yozuvning TO'LIQ pitch konturini (`PitchFrame`,
  /// Hz) `maqom_contours.json` bilan bir xil koordinata tizimiga
  /// (tonikaga nisbatan semiton) aylantiradi. Faqat "voiced" nuqtalar
  /// kiritiladi.
  List<MaqomPoint> _userContourPoints(
    List<PitchFrame> frames,
    double tonicHz,
  ) {
    final points = <MaqomPoint>[];
    for (final f in frames) {
      if (!f.voiced || f.frequencyHz <= 0 || tonicHz <= 0) continue;
      final semitone = 12 * (math.log(f.frequencyHz / tonicHz) / math.ln2);
      points.add(MaqomPoint(f.timestampMs / 1000.0, semitone));
    }
    return points;
  }

  @override
  void initState() {
    super.initState();
    if (_maqomsWithContourData.contains(widget.phrase.maqam.name)) {
      _maqomDataFuture = MaqomContourRepository.load(widget.phrase.maqam.name);
    }
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
                    'Pitch shakli',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _buildPitchShapeChart(result),
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

  /// v1.27: eski "Chiziq/Piano-roll/Farq/Qoplama" tanlovchisi olib
  /// tashlandi — o'rniga "To'liq namuna" va mashq ekrani bilan BIR
  /// XIL uslub: `maqom_contours.json`dan reference egri chizig'i +
  /// foydalanuvchining TO'LIQ yozib olingan ovozi ustma-ust.
  ///
  /// Agar joriy jumla+maqom uchun reference kontur ma'lumoti mavjud
  /// bo'lmasa (masalan, Iqomat — maqom tushunchasi yo'q), faqat
  /// foydalanuvchi konturi (reference'siz) ko'rsatiladi — xato
  /// bermaydi.
  Widget _buildPitchShapeChart(AnalysisResult result) {
    final future = _maqomDataFuture;
    final phraseId = _maqomContourPhraseId;

    if (future == null || phraseId == null) {
      return _buildUserOnlyFallback(result);
    }

    return FutureBuilder<MaqomData>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return _buildUserOnlyFallback(result);
        }
        if (!snap.hasData) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        MaqomPhrase? refPhrase;
        for (final p in snap.data!.phrases) {
          if (p.id == phraseId) {
            refPhrase = p;
            break;
          }
        }
        if (refPhrase == null) return _buildUserOnlyFallback(result);

        return MaqomPhraseChart(
          phrase: refPhrase,
          height: 200,
          showLatinLabel: true,
          liveUserPoints: _userContourPoints(
            result.pitchContour,
            snap.data!.tonicHz,
          ),
        );
      },
    );
  }

  /// v1.27: reference kontur mavjud bo'lmagan holatlar uchun (masalan
  /// Iqomat) — foydalanuvchi ovozining o'zini, oddiy vaqt/chastota
  /// o'qi bilan, reference'siz ko'rsatadi. Xuddi shu `MaqomPhraseChart`
  /// chizuvchisidan foydalanadi (bo'sh "reference" nuqta ro'yxati
  /// bilan) — alohida chizish kodi yaratilmaydi.
  Widget _buildUserOnlyFallback(AnalysisResult result) {
    final userPoints = <MaqomPoint>[];
    for (final f in result.pitchContour) {
      if (!f.voiced || f.frequencyHz <= 0) continue;
      // Reference tonika yo'q — 1 Hz'ga nisbatan semiton (faqat
      // NISBIY shaklni ko'rsatish uchun, mutlaq balandlik emas).
      final semitone = 12 * (math.log(f.frequencyHz) / math.ln2);
      userPoints.add(
        MaqomPoint(f.timestampMs / 1000.0, semitone),
      );
    }
    if (userPoints.isEmpty) {
      return const Text(
        'Pitch shaklini chizish uchun yetarli ovoz aniqlanmadi.',
        style: TextStyle(color: Colors.black45, fontSize: 12),
      );
    }
    final placeholderPhrase = MaqomPhrase(
      id: 'user_only',
      labelArabic: '',
      labelLatin: '',
      fajrOnly: false,
      durationSec: userPoints.last.t,
      points: userPoints,
      trillZones: const [],
    );
    return MaqomPhraseChart(
      phrase: placeholderPhrase,
      height: 200,
      showLatinLabel: false,
      lineColor: const Color(0xFF2563EB),
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
