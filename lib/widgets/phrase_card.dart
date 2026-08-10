import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/maqam.dart';
import '../models/phrase.dart';

class PhraseCard extends StatelessWidget {
  final Phrase phrase;

  const PhraseCard({super.key, required this.phrase});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              phrase.arabicText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              phrase.transliteration,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              phrase.meaningUz,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (phrase.repeatCount > 1) ...[
              const SizedBox(height: 10),
              Chip(
                label: Text('${phrase.repeatCount} marta'),
                backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Maqom: ${phrase.maqam.label}',
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}
