import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pitch_frame.dart';

/// v1.10: "Farq (deviation)" grafigi — ikkita alohida chiziq o'rniga,
/// faqat foydalanuvchi va reference orasidagi FARQNI (semitonlarda)
/// vaqt bo'ylab ko'rsatadi. Nol chiziq — "aynan mos" degani; undan
/// yuqori — user balandroq, past — user pastroq.
///
/// MUHIM: bu klass faqat TAQDIMOT (widget) qatlamida ishlaydi — hech
/// qanday tahlil algoritmiga (YIN, ReferencePitchComparator) tegmaydi
/// yoki ularni chaqirmaydi. U faqat allaqachon hisoblangan
/// `PitchFrame` ro'yxatlarini o'z ichida (widget darajasida) qayta
/// namunalab (resample), chizish uchun ishlatadi.
class PitchDeviationChart extends StatelessWidget {
  final List<PitchFrame> userFrames;
  final double userDurationSeconds;
  final List<PitchFrame> referenceFrames;
  final double referenceDurationSeconds;

  static const int _gridPoints = 60;

  const PitchDeviationChart({
    super.key,
    required this.userFrames,
    required this.userDurationSeconds,
    required this.referenceFrames,
    required this.referenceDurationSeconds,
  });

  List<double?> _resample(List<PitchFrame> frames, double durationSeconds) {
    final grid = List<double?>.filled(_gridPoints, null);
    if (frames.isEmpty || durationSeconds <= 0) return grid;
    final totalMs = durationSeconds * 1000;
    for (int i = 0; i < _gridPoints; i++) {
      final targetMs = (i / (_gridPoints - 1)) * totalMs;
      PitchFrame? nearest;
      double bestDelta = double.infinity;
      for (final frame in frames) {
        final delta = (frame.timestampMs - targetMs).abs().toDouble();
        if (delta < bestDelta) {
          bestDelta = delta;
          nearest = frame;
        }
      }
      if (nearest != null && nearest.voiced) grid[i] = nearest.frequencyHz;
    }
    return grid;
  }

  @override
  Widget build(BuildContext context) {
    final userGrid = _resample(userFrames, userDurationSeconds);
    final refGrid = _resample(referenceFrames, referenceDurationSeconds);

    final diffs = <double?>[];
    for (int i = 0; i < _gridPoints; i++) {
      final u = userGrid[i];
      final r = refGrid[i];
      if (u == null || r == null || u <= 0 || r <= 0) {
        diffs.add(null);
      } else {
        diffs.add(12.0 * (math.log(u) - math.log(r)) / math.ln2);
      }
    }

    final voicedDiffs = diffs.whereType<double>().toList();
    if (voicedDiffs.isEmpty) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: Text(
            'Farqni hisoblash uchun umumiy ovozli qism yo\'q',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: CustomPaint(
            painter: _DeviationPainter(diffs: diffs),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(width: 10, height: 2, color: Colors.black26),
            const SizedBox(width: 6),
            const Text(
              'Nol chiziq = reference bilan aynan mos',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeviationPainter extends CustomPainter {
  final List<double?> diffs;

  _DeviationPainter({required this.diffs});

  @override
  void paint(Canvas canvas, Size size) {
    final voiced = diffs.whereType<double>().toList();
    if (voiced.isEmpty) return;

    // Simmetrik shkala: 0 markazda, ikki tomonga eng katta |farq|
    // qadar (kamida ±3 semiton, chizilishi uchun).
    final maxAbs = math.max(
      3.0,
      voiced.map((d) => d.abs()).reduce((a, b) => a > b ? a : b),
    );

    final zeroY = size.height / 2;
    final scale = (size.height / 2) / maxAbs;

    // Nol chiziq.
    final zeroPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);

    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset? previous;
    for (int i = 0; i < diffs.length; i++) {
      final d = diffs[i];
      final x = (i / (diffs.length - 1)) * size.width;
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
  }

  @override
  bool shouldRepaint(covariant _DeviationPainter oldDelegate) =>
      oldDelegate.diffs != diffs;
}
