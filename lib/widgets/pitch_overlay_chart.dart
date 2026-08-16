import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pitch_frame.dart';

/// v1.10: "Normallashtirilgan qoplama" grafigi — ikkala konturni
/// o'zining O'RTACHA balandligiga nisbatan markazlashtirib chizadi.
/// Bu — foydalanuvchi va reference ovoz registri (masalan, past/baland
/// ovozli odamlar) farqli bo'lsa ham, faqat KONTUR SHAKLINI (ko'tarilish/
/// tushish naqshini) solishtirish imkonini beradi — mutlaq balandlik
/// farqi chalg'itmaydi.
///
/// Faqat taqdimot qatlami — tahlil algoritmiga tegmaydi.
class PitchOverlayChart extends StatelessWidget {
  final List<PitchFrame> userFrames;
  final double userDurationSeconds;
  final List<PitchFrame> referenceFrames;
  final double referenceDurationSeconds;

  const PitchOverlayChart({
    super.key,
    required this.userFrames,
    required this.userDurationSeconds,
    required this.referenceFrames,
    required this.referenceDurationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final userVoiced = userFrames.where((f) => f.voiced).toList();
    final refVoiced = referenceFrames.where((f) => f.voiced).toList();
    if (userVoiced.isEmpty || refVoiced.isEmpty) {
      return const SizedBox(
        height: 130,
        child: Center(
          child: Text(
            'Qoplash uchun ikkala tomonda ham ovozli qism kerak',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      );
    }

    final userMeanLog = _meanLogHz(userVoiced);
    final refMeanLog = _meanLogHz(refVoiced);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(
            painter: _OverlayPainter(
              userFrames: userFrames,
              userDurationSeconds: userDurationSeconds,
              userMeanLogHz: userMeanLog,
              referenceFrames: referenceFrames,
              referenceDurationSeconds: referenceDurationSeconds,
              referenceMeanLogHz: refMeanLog,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(width: 10, height: 2, color: Colors.deepOrange),
            const SizedBox(width: 6),
            const Text(
              'Siz (o\'z o\'rtachangizga nisbatan)',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
        Row(
          children: [
            Container(width: 10, height: 2, color: Colors.teal),
            const SizedBox(width: 6),
            const Text(
              'Reference (o\'z o\'rtachasiga nisbatan)',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  double _meanLogHz(List<PitchFrame> voiced) {
    final logs = voiced.map((f) => math.log(f.frequencyHz) / math.ln2);
    return logs.reduce((a, b) => a + b) / voiced.length;
  }
}

class _OverlayPainter extends CustomPainter {
  final List<PitchFrame> userFrames;
  final double userDurationSeconds;
  final double userMeanLogHz;
  final List<PitchFrame> referenceFrames;
  final double referenceDurationSeconds;
  final double referenceMeanLogHz;

  _OverlayPainter({
    required this.userFrames,
    required this.userDurationSeconds,
    required this.userMeanLogHz,
    required this.referenceFrames,
    required this.referenceDurationSeconds,
    required this.referenceMeanLogHz,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final userRel = userFrames
        .where((f) => f.voiced)
        .map(
          (f) => 12.0 * (math.log(f.frequencyHz) / math.ln2 - userMeanLogHz),
        )
        .toList();
    final refRel = referenceFrames
        .where((f) => f.voiced)
        .map(
          (f) =>
              12.0 * (math.log(f.frequencyHz) / math.ln2 - referenceMeanLogHz),
        )
        .toList();

    if (userRel.isEmpty && refRel.isEmpty) return;

    final allRel = [...userRel, ...refRel];
    final maxAbs = math.max(
      2.0,
      allRel.map((v) => v.abs()).reduce((a, b) => a > b ? a : b),
    );

    final zeroY = size.height / 2;
    final scale = (size.height / 2) / maxAbs;

    final zeroPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);

    _drawSeries(
      canvas,
      size,
      userFrames,
      userDurationSeconds,
      userMeanLogHz,
      zeroY,
      scale,
      Colors.deepOrange,
    );
    _drawSeries(
      canvas,
      size,
      referenceFrames,
      referenceDurationSeconds,
      referenceMeanLogHz,
      zeroY,
      scale,
      Colors.teal,
    );
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<PitchFrame> frames,
    double durationSeconds,
    double meanLogHz,
    double zeroY,
    double scale,
    Color color,
  ) {
    if (frames.isEmpty || durationSeconds <= 0) return;
    final totalMs = durationSeconds * 1000;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset? previous;
    for (final frame in frames) {
      final rawX = frame.timestampMs / totalMs;
      final x = (rawX < 0 ? 0.0 : (rawX > 1 ? 1.0 : rawX)) * size.width;

      if (!frame.voiced) {
        previous = null;
        continue;
      }

      final relSemitone =
          12.0 * (math.log(frame.frequencyHz) / math.ln2 - meanLogHz);
      final y = zeroY - (relSemitone * scale);
      final clampedY = y < 0 ? 0.0 : (y > size.height ? size.height : y);
      final point = Offset(x, clampedY);

      if (previous != null) {
        canvas.drawLine(previous, point, paint);
      }
      previous = point;
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      oldDelegate.userFrames != userFrames ||
      oldDelegate.referenceFrames != referenceFrames;
}
