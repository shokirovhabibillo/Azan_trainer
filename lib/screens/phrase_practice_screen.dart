import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/phrase.dart';
import '../models/practice_session.dart';
import '../services/audio/audio_player_service.dart';
import '../services/audio/audio_recorder_service.dart';
import '../services/audio/reference_audio_checker.dart';
import '../services/progress_service.dart';
import '../widgets/phrase_card.dart';
import 'result_screen.dart';

enum _RecordState { idle, recording, recorded }

class PhrasePracticeScreen extends StatefulWidget {
  final Phrase phrase;
  final VoidCallback? onNext;

  const PhrasePracticeScreen({
    super.key,
    required this.phrase,
    this.onNext,
  });

  @override
  State<PhrasePracticeScreen> createState() => _PhrasePracticeScreenState();
}

class _PhrasePracticeScreenState extends State<PhrasePracticeScreen> {
  final _recorder = AudioRecorderService();
  final _player = AudioPlayerService();
  final _progress = ProgressService();
  final _referenceChecker = const ReferenceAudioChecker();

  _RecordState _state = _RecordState.idle;
  String? _recordingPath;
  Duration _recordedDuration = Duration.zero;
  String? _errorMessage;

  /// v1.2: reference tugmasi mavjudlikka qarab yoqilgan/o'chirilgan
  /// bo'lishi kerak (talab #5). null = hali tekshirilmoqda.
  bool? _referenceAvailable;

  /// v1.3: Play/Pause/Stop tugmalarini to'g'ri holatda ko'rsatish uchun.
  PlayerState _referencePlayerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _checkReferenceAvailability();
    _player.onStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _referencePlayerState = state);
    });
  }

  Future<void> _checkReferenceAvailability() async {
    final exists =
        await _referenceChecker.exists(widget.phrase.referenceAudioFile);
    if (!mounted) return;
    setState(() => _referenceAvailable = exists);
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playReference() async {
    final ok = await _player.playAsset(widget.phrase.referenceAudioFile);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reference audio hali qo\'shilmagan (assets/audio/ ichida topilmadi)',
          ),
        ),
      );
    }
  }

  Future<void> _pauseReference() => _player.pause();

  Future<void> _resumeReference() => _player.resume();

  Future<void> _stopReference() => _player.stop();

  Future<void> _toggleRecording() async {
    setState(() => _errorMessage = null);
    try {
      if (_state == _RecordState.recording) {
        final outcome = await _recorder.stop();
        setState(() {
          _state = _RecordState.recorded;
          _recordingPath = outcome?.filePath;
          _recordedDuration = outcome?.duration ?? Duration.zero;
        });
      } else {
        await _recorder.start(phraseId: widget.phrase.id);
        setState(() => _state = _RecordState.recording);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Mikrofonga ruxsat kerak: $e';
        _state = _RecordState.idle;
      });
    }
  }

  Future<void> _reRecord() async {
    setState(() {
      _state = _RecordState.idle;
      _recordingPath = null;
      _recordedDuration = Duration.zero;
    });
  }

  Future<void> _goToAnalysis() async {
    if (_recordingPath == null) return;

    final session = PracticeSession(
      phraseId: widget.phrase.id,
      recordingPath: _recordingPath!,
      timestamp: DateTime.now(),
    );
    await _progress.saveSession(session);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          phrase: widget.phrase,
          recordingPath: _recordingPath!,
          onRetry: () {
            Navigator.of(context).pop();
            _reRecord();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PhraseCard(phrase: widget.phrase),
          const SizedBox(height: 20),
          _buildReferenceControls(),
          if (_referenceAvailable == false) ...[
            const SizedBox(height: 6),
            const Text(
              'Reference audio hali qo\'shilmagan',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
          const SizedBox(height: 28),
          _buildRecordButton(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          if (_state == _RecordState.recorded) ...[
            const SizedBox(height: 12),
            Text(
              'Yozib olindi (${_recordedDuration.inSeconds}s)',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _player.playFile(_recordingPath!),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Eshitish'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _reRecord,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Qayta yozish'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _goToAnalysis,
              icon: const Icon(Icons.insights),
              label: const Text('Tahlil qilish'),
            ),
          ],
          if (widget.onNext != null) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: widget.onNext,
              child: const Text('Keyingi jumlaga o\'tish →'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferenceControls() {
    final available = _referenceAvailable == true;
    final isPlaying = _referencePlayerState == PlayerState.playing;
    final isPaused = _referencePlayerState == PlayerState.paused;

    return Column(
      children: [
        Text(
          'Reference audio',
          style: TextStyle(
            fontSize: 12,
            color: available ? Colors.black54 : Colors.black38,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: available && !isPlaying
                  ? (isPaused ? _resumeReference : _playReference)
                  : null,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Play',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: available && isPlaying ? _pauseReference : null,
              icon: const Icon(Icons.pause),
              tooltip: 'Pause',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: available && (isPlaying || isPaused)
                  ? _stopReference
                  : null,
              icon: const Icon(Icons.stop),
              tooltip: 'Stop',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    final isRecording = _state == _RecordState.recording;
    return GestureDetector(
      onTap: _toggleRecording,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? Colors.redAccent : AppTheme.primary,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.redAccent : AppTheme.primary)
                  .withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}
