import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pitch_frame.dart';
import '../services/analysis/realtime_pitch_analyzer.dart';

/// v1.14: mashq qilish vaqtida (ovoz yozilayotganda) ko'rsatiladigan
/// jonli "Farq (deviation)" grafigi.
///
/// Reference kontur OLDINDAN hisoblangan (statik), foydalanuvchi
/// konturi esa vaqt o'tishi bilan `livePitchSamples` ro'yxatiga
/// qo'shilib boradi — har safar yangi namuna kelganda widget qayta
/// chiziladi.
class LivePitchDeviationMeter extends StatelessWidget {
  final List<PitchFrame>? referenceContour;
  final double? referenceDurationSeconds;
  final List<RealtimePitchSample> livePitchSamples;
  final Duration elapsed;

  const LivePitchDeviationMeter({
    super.key,
    required this.referenceContour,
    required this.referenceDurationSeconds,
    required this.livePitchSamples,
    required this.elapsed,
  });

  bool get _hasReference =>
      referenceContour != null &&
      referenceContour!.isNotEmpty &&
      (referenceDurationSeconds ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasReference) {
      return Container(
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Na\'muna ovoz mavjud emas',
          style: TextStyle(color: Colors.black45, fontSize: 13),
        ),
      );
    }

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        painter: _LiveDeviationPainter(
          referenceContour: referenceContour!,
          referenceDurationSeconds: referenceDurationSeconds!,
          livePitchSamples: livePitchSamples,
          elapsedMs: elapsed.inMilliseconds,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LiveDeviationPainter extends CustomPainter {
  final List<PitchFrame> referenceContour;
  final double referenceDurationSeconds;
  final List<RealtimePitchSample> livePitchSamples;
  final int elapsedMs;

  _LiveDeviationPainter({
    required this.referenceContour,
    required this.referenceDurationSeconds,
    required this.livePitchSamples,
    required this.elapsedMs,
  });

  double? _referenceHzAt(int timestampMs) {
    if (referenceContour.isEmpty) return null;
    PitchFrame? nearest;
    int bestDelta = 1 << 30;
    for (final frame in referenceContour) {
      final delta = (frame.timestampMs - timestampMs).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        nearest = frame;
      }
    }
    return (nearest != null && nearest.voiced) ? nearest.frequencyHz : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final referenceTotalMs = (referenceDurationSeconds * 1000).round();
    final zeroY = size.height / 2;

    final zeroPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);

    if (livePitchSamples.isEmpty) return;

    final diffs = <double?>[];
    for (final sample in livePitchSamples) {
      final refHz = _referenceHzAt(sample.timestampMs);
      if (!sample.voiced || sample.frequencyHz <= 0 || refHz == null) {
        diffs.add(null);
        continue;
      }
      diffs.add(
        12.0 * (math.log(sample.frequencyHz) - math.log(refHz)) / math.ln2,
      );
    }

    final voiced = diffs.whereType<double>().toList();
    final maxAbs = voiced.isEmpty
        ? 3.0
        : math.max(3.0, voiced.map((d) => d.abs()).reduce(math.max));
    final scale = (size.height / 2) / maxAbs;

    final linePaint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset? previous;
    for (int i = 0; i < livePitchSamples.length; i++) {
      final sample = livePitchSamples[i];
      final d = diffs[i];
      final xRatioRaw =
          referenceTotalMs <= 0 ? 0.0 : sample.timestampMs / referenceTotalMs;
      final xRatio = xRatioRaw < 0 ? 0.0 : (xRatioRaw > 1 ? 1.0 : xRatioRaw);
      final x = xRatio * size.width;

      if (d == null) {
        previous = null;
        continue;
      }
      final y = zeroY - (d * scale);
      final clampedY = y < 0 ? 0.0 : (y > size.height ? size.height : y);
      final point = Offset(x, clampedY);
      if (previous != null) {
        linePaint.color = d >= 0 ? Colors.deepOrange : Colors.blue;
        canvas.drawLine(previous, point, linePaint);
      }
      previous = point;
    }

    if (referenceTotalMs > 0) {
      final cursorRatioRaw = elapsedMs / referenceTotalMs;
      final cursorRatio =
          cursorRatioRaw < 0 ? 0.0 : (cursorRatioRaw > 1 ? 1.0 : cursorRatioRaw);
      final cursorX = cursorRatio * size.width;
      final cursorPaint = Paint()
        ..color = Colors.black38
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(cursorX, 0),
        Offset(cursorX, size.height),
        cursorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveDeviationPainter oldDelegate) =>
      oldDelegate.livePitchSamples.length != livePitchSamples.length ||
      oldDelegate.elapsedMs != elapsedMs;
}
