import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/phrase.dart';
import '../models/phrase_practice_state.dart';

/// v1.7 (talab #5): mashq sessiyasi davomida barcha jumlalarning
/// holatini (audio ✓/—, tahlil ✓/—) ro'yxat sifatida ko'rsatadi.
///
/// Bu ekran shunchaki ko'rsatish uchun — u holatning o'zini saqlamaydi
/// (`PracticeSessionController` — single source of truth,
/// `PracticeScreen`da qoladi). Foydalanuvchi biror jumlani bossa, shu
/// jumlaning indeksi bilan ekran yopiladi (`Navigator.pop(index)`) —
/// `PracticeScreen` shu indeksga o'tadi va jumlaning to'liq holati
/// (recording + tahlil) qayta ko'rinadi.
class AzonResultsScreen extends StatelessWidget {
  final String title;
  final List<Phrase> phrases;
  final Map<String, PhrasePracticeState> states;

  const AzonResultsScreen({
    super.key,
    required this.title,
    required this.phrases,
    required this.states,
  });

  @override
  Widget build(BuildContext context) {
    final recordedCount =
        states.values.where((s) => s.hasRecording).length;
    final analyzedCount = states.values.where((s) => s.hasAnalysis).length;

    return Scaffold(
      appBar: AppBar(title: Text('$title — Natijalar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Audio: $recordedCount/${phrases.length}   '
              'Tahlil: $analyzedCount/${phrases.length}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: phrases.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final phrase = phrases[index];
                final state = states[phrase.id];
                final hasAudio = state?.hasRecording ?? false;
                final hasAnalysis = state?.hasAnalysis ?? false;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.12),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(
                    '${index + 1}/${phrases.length} — ${phrase.transliteration}',
                  ),
                  subtitle: Text(
                    'Audio: ${hasAudio ? "✓" : "—"}    '
                    'Tahlil: ${hasAnalysis ? "✓" : "—"}',
                    style: TextStyle(
                      color: hasAudio ? Colors.black87 : Colors.black38,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
