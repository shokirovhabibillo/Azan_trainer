import 'package:flutter/material.dart';

import '../models/phrase.dart';
import '../models/phrase_practice_state.dart';
import '../services/practice_session_controller.dart';
import 'azon_results_screen.dart';
import 'phrase_practice_screen.dart';

/// Berilgan jumlalar ketma-ketligi bo'ylab yuradigan konteyner ekran.
///
/// v1.7: har bir jumlaning to'liq amaliyot holati (yozib olingan
/// audio HAM tahlil natijasi) `PracticeSessionController`da, jumla ID
/// (`Phrase.id`) bo'yicha saqlanadi — bu "single source of truth".
/// `PhrasePracticeScreen` (bola widget) har safar jumla almashganda
/// YANGI State bilan qayta yaratiladi (`ValueKey` orqali), lekin uning
/// boshlang'ich holati shu controller'dan tiklanadi, va har qanday
/// o'zgarish (yangi recording, qayta yozish, yangi tahlil natijasi)
/// darhol shu controller'ga qaytarib yoziladi. Shu tufayli:
///   - jumlalar orasida o'tganda oldingi recordinglar VA tahlil
///     natijalari yo'qolmaydi;
///   - playback va tahlil har doim FAQAT joriy jumlaning o'z
///     audiosidan/natijasidan foydalanadi;
///   - yozilmagan jumla uchun boshqa jumla audiosi hech qachon
///     ishlatilmaydi.
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

  /// v1.7: sof Dart controller — barcha jumlalarning holatini saqlaydi.
  /// Kelajakda persistence (Hive/SQLite) qo'shilganda, shu klassning
  /// implementatsiyasi almashtirilishi kifoya (talab #6).
  final _controller = PracticeSessionController();

  void _handleStateChanged(String phraseId, PhrasePracticeState? state) {
    setState(() {
      _controller.update(phraseId, state);
    });
  }

  Future<void> _openResultsList() async {
    final selectedIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => AzonResultsScreen(
          title: widget.title,
          phrases: widget.phrases,
          states: _controller.all,
        ),
      ),
    );
    if (selectedIndex != null && mounted) {
      setState(() => _index = selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrases[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} (${_index + 1}/${widget.phrases.length})'),
        actions: [
          IconButton(
            onPressed: _openResultsList,
            icon: const Icon(Icons.list_alt),
            tooltip: 'Natijalar',
          ),
        ],
      ),
      body: PhrasePracticeScreen(
        // Har bir jumla o'ziga xos, mustaqil UI holatiga ega bo'lishi
        // uchun ValueKey saqlanadi — lekin bu holat yo'qolmaydi, chunki
        // initialState orqali controller'dan tiklanadi.
        key: ValueKey(phrase.id),
        phrase: phrase,
        initialState: _controller.stateFor(phrase.id),
        onStateChanged: (state) => _handleStateChanged(phrase.id, state),
        onPrevious: _index > 0 ? () => setState(() => _index--) : null,
        onNext: _index < widget.phrases.length - 1
            ? () => setState(() => _index++)
            : null,
      ),
    );
  }
}
