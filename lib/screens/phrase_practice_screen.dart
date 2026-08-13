import 'dart:io';

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/maqam_reference_catalog.dart';
import '../models/analysis_result.dart';
import '../models/duration_comparison_result.dart';
import '../models/maqam.dart';
import '../models/phrase.dart';
import '../models/phrase_practice_state.dart';
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

  /// v1.7: shu jumla uchun oldin yozib olingan audio va (agar mavjud
  /// bo'lsa) tahlil natijasi. `PracticeScreen`dan (aniqrog'i, uning
  /// `PracticeSessionController`idan) keladi — jumlalar orasida
  /// o'tishda to'liq holatni tiklash uchun ishlatiladi.
  final PhrasePracticeState? initialState;

  /// v1.7: holat o'zgarganda (yangi yozuv, qayta yozish, yangi tahlil
  /// natijasi) ota-ona darhol xabardor qilinadi — `null` uzatilsa,
  /// bu jumla uchun holat butunlay tozalanadi (masalan, "Qayta
  /// yozish" bosilganda, yangi yozuv tugagunga qadar).
  final ValueChanged<PhrasePracticeState?> onStateChanged;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PhrasePracticeScreen({
    super.key,
    required this.phrase,
    required this.onStateChanged,
    this.initialState,
    this.onPrevious,
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

  /// v1.7: shu jumla uchun keshlangan tahlil natijasi (agar bo'lsa).
  /// Bu qiymatlar mavjud bo'lsa, "Tahlil qilish" bosilganda
  /// PitchAnalyzer/DurationAnalyzer QAYTA chaqirilmaydi — to'g'ridan
  /// to'g'ri saqlangan natija ko'rsatiladi.
  AnalysisResult? _cachedAnalysisResult;
  DurationComparisonResult? _cachedDurationResult;

  /// v1.2: reference tugmasi mavjudlikka qarab yoqilgan/o'chirilgan
  /// bo'lishi kerak (talab #5). null = hali tekshirilmoqda.
  bool? _referenceAvailable;

  /// v1.3: Play/Pause/Stop tugmalarini to'g'ri holatda ko'rsatish uchun.
  PlayerState _referencePlayerState = PlayerState.stopped;

  /// v1.10: agar bu jumla uchun bir nechta maqom variantida reference
  /// audio mavjud bo'lsa (masalan Bayati/Lami/Kurd), foydalanuvchi
  /// tanlagan variant shu yerda saqlanadi. Boshlang'ich qiymat —
  /// jumlaning standart (`widget.phrase.maqam`) varianti.
  late Maqam _selectedMaqam;

  /// v1.10: joriy tanlangan maqom variantiga mos, HAQIQIY ishlatiladigan
  /// `Phrase` obyekti — faqat `referenceAudioFile`/`maqam` maydonlari
  /// almashtirilgan, boshqa hamma narsa (matn, takrorlanish soni)
  /// o'zgarmagan. `PitchAnalyzer`/`DurationAnalyzer` (himoyalangan
  /// fayllar) buni oddiy `Phrase` sifatida qabul qiladi — ular ko'p
  /// maqom haqida umuman "bilishmaydi".
  Phrase get _effectivePhrase {
    final variants = MaqamReferenceCatalog.variantsFor(widget.phrase.id);
    if (variants.isEmpty) return widget.phrase;
    final selected = variants.firstWhere(
      (v) => v.maqam == _selectedMaqam,
      orElse: () => variants.first,
    );
    return widget.phrase.copyWithReference(
      referenceAudioFile: selected.audioFile,
      maqam: selected.maqam,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedMaqam = widget.phrase.maqam;
    _restoreInitialState();
    _checkReferenceAvailability();
    _player.onStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _referencePlayerState = state);
    });
  }

  /// v1.7: ota-onadan kelgan holatni tiklaydi — lekin avval audio
  /// faylning DISKDA amalda mavjudligini tekshiradi (talab #2: "Audio
  /// path faqat xotirada emas, amalda mavjud faylga ishora qilishi
  /// tekshirilsin"). Fayl topilmasa, bu jumla "yozilmagan" deb
  /// hisoblanadi va ota-onadagi holat ham tozalanadi.
  Future<void> _restoreInitialState() async {
    final initial = widget.initialState;
    if (initial == null || !initial.hasRecording) return;

    final path = initial.recordingPath!;
    final exists = await File(path).exists();
    if (!mounted) return;

    if (exists) {
      setState(() {
        _state = _RecordState.recorded;
        _recordingPath = path;
        _recordedDuration = initial.recordingDuration;
        _cachedAnalysisResult = initial.analysisResult;
        _cachedDurationResult = initial.durationResult;
      });
    } else {
      widget.onStateChanged(null);
    }
  }

  Future<void> _checkReferenceAvailability() async {
    final exists =
        await _referenceChecker.exists(_effectivePhrase.referenceAudioFile);
    if (!mounted) return;
    setState(() => _referenceAvailable = exists);
  }

  /// v1.10: foydalanuvchi boshqa maqom variantini tanlaganda
  /// chaqiriladi. Reference mavjudligini qayta tekshiradi va — MUHIM —
  /// eski maqomga tegishli bo'lgan keshlangan tahlil natijasini bekor
  /// qiladi (aks holda foydalanuvchi Bayati bilan solishtirilgan
  /// natijani Kurd tanlagandan keyin ham ko'rib qolishi mumkin edi).
  void _onMaqamSelected(Maqam maqam) {
    if (maqam == _selectedMaqam) return;
    setState(() {
      _selectedMaqam = maqam;
      _referenceAvailable = null;
      _cachedAnalysisResult = null;
      _cachedDurationResult = null;
    });
    _checkReferenceAvailability();
    if (_recordingPath != null) {
      widget.onStateChanged(
        PhrasePracticeState(
          recordingPath: _recordingPath!,
          recordingDuration: _recordedDuration,
        ),
      );
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playReference() async {
    final ok = await _player.playAsset(_effectivePhrase.referenceAudioFile);
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
          // v1.7: yangi recording eski tahlil natijasini bekor qiladi
          // — u ESKI audioga tegishli edi.
          _cachedAnalysisResult = null;
          _cachedDurationResult = null;
        });
        if (_recordingPath != null) {
          widget.onStateChanged(
            PhrasePracticeState(
              recordingPath: _recordingPath!,
              recordingDuration: _recordedDuration,
            ),
          );
        }
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
      _cachedAnalysisResult = null;
      _cachedDurationResult = null;
    });
    widget.onStateChanged(null);
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
          phrase: _effectivePhrase,
          recordingPath: _recordingPath!,
          // v1.7: agar bu jumla uchun tahlil oldin hisoblangan bo'lsa,
          // shu yerdan uzatamiz — ResultScreen uni qayta hisoblamaydi.
          cachedResult: _cachedAnalysisResult,
          cachedDurationResult: _cachedDurationResult,
          onAnalysisComputed: (result, durationResult) {
            if (!mounted) return;
            setState(() {
              _cachedAnalysisResult = result;
              _cachedDurationResult = durationResult;
            });
            widget.onStateChanged(
              PhrasePracticeState(
                recordingPath: _recordingPath!,
                recordingDuration: _recordedDuration,
                analysisResult: result,
                durationResult: durationResult,
              ),
            );
          },
          onRetry: () {
            Navigator.of(context).pop();
            _reRecord();
          },
        ),
      ),
    );
  }

  /// v1.7: keshlangan natijaga qayta o'tish uchun (qayta hisoblamasdan).
  void _reopenCachedAnalysis() {
    if (_recordingPath == null ||
        _cachedAnalysisResult == null ||
        _cachedDurationResult == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          phrase: _effectivePhrase,
          recordingPath: _recordingPath!,
          cachedResult: _cachedAnalysisResult,
          cachedDurationResult: _cachedDurationResult,
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
    final hasCachedAnalysis =
        _cachedAnalysisResult != null && _cachedDurationResult != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PhraseCard(phrase: _effectivePhrase),
          const SizedBox(height: 20),
          _buildMaqamSelector(),
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
            if (hasCachedAnalysis) ...[
              GestureDetector(
                onTap: _reopenCachedAnalysis,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Tahlil tayyor',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed:
                  hasCachedAnalysis ? _reopenCachedAnalysis : _goToAnalysis,
              icon: const Icon(Icons.insights),
              label: Text(
                hasCachedAnalysis ? 'Natijani ko\'rish' : 'Tahlil qilish',
              ),
            ),
          ],
          if (widget.onPrevious != null || widget.onNext != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onPrevious != null)
                  TextButton(
                    onPressed: widget.onPrevious,
                    child: const Text('← Oldingi jumla'),
                  ),
                if (widget.onPrevious != null && widget.onNext != null)
                  const SizedBox(width: 16),
                if (widget.onNext != null)
                  TextButton(
                    onPressed: widget.onNext,
                    child: const Text('Keyingi jumlaga o\'tish →'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaqamSelector() {
    final variants = MaqamReferenceCatalog.variantsFor(widget.phrase.id);
    if (variants.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const Text(
            'Maqom',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: variants.map((v) {
              final selected = v.maqam == _selectedMaqam;
              return ChoiceChip(
                label: Text(v.maqam.label),
                selected: selected,
                selectedColor: AppTheme.primary.withOpacity(0.2),
                onSelected: (_) => _onMaqamSelected(v.maqam),
              );
            }).toList(),
          ),
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
