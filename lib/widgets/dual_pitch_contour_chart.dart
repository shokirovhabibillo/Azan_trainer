import 'package:flutter/material.dart';

import '../models/pitch_frame.dart';

/// Reference va user pitch contourlarini bitta grafikda, vaqt bo'yicha
/// normalize qilingan (0..1) o'qda ko'rsatadi.
///
/// Reference mavjud bo'lmasa ([referenceFrames] null yoki bo'sh),
/// faqat user contour chiziladi (talab #6).
class DualPitchContourChart extends StatelessWidget {
  final List<PitchFrame> userFrames;
  final double userDurationSeconds;
  final List<PitchFrame>? referenceFrames;
  final double? referenceDurationSeconds;

  const DualPitchContourChart({
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
        height: 90,
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
          height: 110,
          width: double.infinity,
          child: CustomPaint(
            painter: _DualContourPainter(
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
            const _LegendDot(color: Colors.deepOrange, label: 'Siz'),
            if (_hasReference) ...[
              const SizedBox(width: 16),
              const _LegendDot(color: Colors.teal, label: 'Reference'),
            ],
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _DualContourPainter extends CustomPainter {
  final List<PitchFrame> userFrames;
  final double userDurationSeconds;
  final List<PitchFrame>? referenceFrames;
  final double? referenceDurationSeconds;

  _DualContourPainter({
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
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset? previous;
    for (final frame in frames) {
      final rawX = frame.timestampMs / totalMs;
      final normalizedX = rawX < 0 ? 0.0 : (rawX > 1 ? 1.0 : rawX);
      final x = normalizedX * size.width;

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
  bool shouldRepaint(covariant _DualContourPainter oldDelegate) =>
      oldDelegate.userFrames != userFrames ||
      oldDelegate.referenceFrames != referenceFrames;
}
