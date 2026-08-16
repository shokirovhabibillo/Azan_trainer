import 'package:flutter/material.dart';

import '../services/analysis/voice_level_analyzer.dart';

/// v1.14: real-vaqt ovoz darajasi ko'rsatkichi — PITCH grafigidan
/// alohida, mustaqil.
class VoiceLevelMeter extends StatelessWidget {
  final VoiceLevelSample? sample;

  const VoiceLevelMeter({super.key, required this.sample});

  @override
  Widget build(BuildContext context) {
    final level = sample?.level ?? 0.0;
    final percent = (level * 100).round();

    Color barColor;
    String label;
    if (sample == null) {
      barColor = Colors.black26;
      label = 'Ovoz darajasi';
    } else if (sample!.isTooQuiet) {
      barColor = Colors.orange;
      label = 'Ovoz juda past';
    } else if (sample!.isTooLoud) {
      barColor = Colors.redAccent;
      label = 'Ovoz juda baland';
    } else {
      barColor = Colors.green;
      label = 'Ovoz darajasi normal';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: level,
            minHeight: 10,
            backgroundColor: Colors.black.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}
