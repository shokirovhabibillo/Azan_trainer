import 'package:flutter/material.dart';

import '../models/pitch_frame.dart';

/// v1.10: "Piano-roll" uslubidagi grafik — gorizontal "yo'llar" (har
/// biri pitch diapazonining bir qismi), foydalanuvchi va reference
/// kontürlari shu yo'llar ustidan harakatlanuvchi chiziq sifatida
/// chiziladi. Vokal-trener ilovalarida keng tarqalgan uslub.
///
/// Faqat taqdimot qatlami — tahlil algoritmiga tegmaydi.
class PitchPianoRollChart extends StatelessWidget {
  final List<PitchFrame> userFrames;
  final double userDurationSeconds;
  final List<PitchFrame>? referenceFrames;
  final double? referenceDurationSeconds;

  static const int _laneCount = 8;

  const PitchPianoRollChart({
    super.key,
    required this.userFrames,
    required this.userDurationSeconds,
    this.referenceFrames,
    this.referenceDurationSeconds,
  });

  bool get _hasReference =>
      referenceFrames != null &&
      referenceFrames!.isNotEmpty &&
      (referenceDurationSeconds ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final userVoiced = userFrames.where((f) => f.voiced).toList();
    if (userVoiced.isEmpty && !_hasReference) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Chizish uchun voiced freym yo\'q',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: _PianoRollPainter(
              userFrames: userFrames,
              userDurationSeconds: userDurationSeconds,
              referenceFrames: _hasReference ? referenceFrames : null,
              referenceDurationSeconds:
                  _hasReference ? referenceDurationSeconds : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(width: 10, height: 10, color: Colors.deepOrange),
            const SizedBox(width: 6),
            const Text('Siz', style: TextStyle(fontSize: 12)),
            if (_hasReference) ...[
              const SizedBox(width: 16),
              Container(width: 10, height: 10, color: Colors.teal),
              const SizedBox(width: 6),
              const Text('Reference', style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ],
    );
  }
}

class _PianoRollPainter extends CustomPainter {
  final List<PitchFrame> userFrames;
  final double userDurationSeconds;
  final List<PitchFrame>? referenceFrames;
  final double? referenceDurationSeconds;

  _PianoRollPainter({
    required this.userFrames,
    required this.userDurationSeconds,
    required this.referenceFrames,
    required this.referenceDurationSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allVoicedHz = <double>[
      ...userFrames.where((f) => f.voiced).map((f) => f.frequencyHz),
      if (referenceFrames != null)
        ...referenceFrames!.where((f) => f.voiced).map((f) => f.frequencyHz),
    ];
    if (allVoicedHz.isEmpty) return;

    final minHz = allVoicedHz.reduce((a, b) => a < b ? a : b);
    final maxHz = allVoicedHz.reduce((a, b) => a > b ? a : b);
    final range = (maxHz - minHz).abs() < 1e-6 ? 1.0 : (maxHz - minHz);

    // Gorizontal "yo'llar" (lanes) — fon chiziqlari.
    const laneCount = PitchPianoRollChart._laneCount;
    final lanePaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    for (int i = 0; i <= laneCount; i++) {
      final y = size.height * i / laneCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lanePaint);
    }

    _drawSeries(
      canvas,
      size,
      userFrames,
      userDurationSeconds,
      minHz,
      range,
      Colors.deepOrange,
    );
    if (referenceFrames != null && referenceDurationSeconds != null) {
      _drawSeries(
        canvas,
        size,
        referenceFrames!,
        referenceDurationSeconds!,
        minHz,
        range,
        Colors.teal,
      );
    }
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<PitchFrame> frames,
    double durationSeconds,
    double minHz,
    double range,
    Color color,
  ) {
    if (frames.isEmpty || durationSeconds <= 0) return;
    final totalMs = durationSeconds * 1000;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
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

      final rawY = (frame.frequencyHz - minHz) / range;
      final normalizedY = rawY < 0 ? 0.0 : (rawY > 1 ? 1.0 : rawY);
      final y = size.height - (normalizedY * size.height);
      final point = Offset(x, y);

      if (previous != null) {
        canvas.drawLine(previous, point, paint);
      }
      previous = point;
    }
  }

  @override
  bool shouldRepaint(covariant _PianoRollPainter oldDelegate) =>
      oldDelegate.userFrames != userFrames ||
      oldDelegate.referenceFrames != referenceFrames;
}
