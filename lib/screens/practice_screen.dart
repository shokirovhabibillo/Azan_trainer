import 'package:flutter/material.dart';

import '../models/phrase.dart';
import 'phrase_practice_screen.dart';

/// Berilgan jumlalar ketma-ketligi bo'ylab yuradigan konteyner ekran.
/// Har bir jumla uchun PhrasePracticeScreen ko'rsatiladi, "Keyingisi"
/// tugmasi bilan ro'yxat bo'ylab siljiydi.
class PracticeScreen extends StatefulWidget {
  final String title;
  final List<Phrase> phrases;

  const PracticeScreen({
    super.key,
    required this.title,
    required this.phrases,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrases[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} (${_index + 1}/${widget.phrases.length})'),
      ),
      body: PhrasePracticeScreen(
        key: ValueKey(phrase.id),
        phrase: phrase,
        onNext: _index < widget.phrases.length - 1
            ? () => setState(() => _index++)
            : null,
      ),
    );
  }
}
