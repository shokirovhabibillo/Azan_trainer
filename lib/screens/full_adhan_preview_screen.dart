import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/full_maqam_adhan_catalog.dart';
import '../data/maqam_reference_catalog.dart';
import '../models/maqam.dart';
import '../models/phrase.dart';
import '../models/prayer_time.dart';
import '../services/audio/audio_player_service.dart';
import '../services/audio/sequential_playback_sequence.dart';
import 'practice_screen.dart';

/// v1.18: tanlangan maqomning TO'LIQ azon namunasini eshittirish
/// uchun ekran.
///
/// MUHIM: bu ekran sof PLAYBACK — hech qanday pitch/duration tahlili,
/// YIN, ReferencePitchComparator bilan aloqasi yo'q.
///
/// IKKI XIL REJIM (avtomatik aniqlanadi, sozlash shart emas):
///   1. Agar `FullMaqamAdhanCatalog`da shu maqom uchun HAQIQIY,
///      uzluksiz yozuv mavjud bo'lsa (masalan, kelajakda katta hajmli
///      versiya o'rnatilsa) — o'sha bitta fayl to'g'ridan-to'g'ri
///      ijro etiladi.
///   2. Aks holda (hozirgi, ilova hajmini kichraytirilgan holatda) —
///      mavjud jumla-darajasidagi fayllar (`MaqamReferenceCatalog`dan,
///      to'g'ri tartibda) BITTASI TUGAGACH IKKINCHISI AVTOMATIK
///      boshlanadigan qilib ijro etiladi. Fayllar JISMONAN
///      birlashtirilmaydi — hech qanday yangi fayl yaratilmaydi,
///      xotira sarflanmaydi. Jumlalar orasidagi 1-2 soniyalik tabiiy
///      tanaffuс — azon ijrosida odatiy hodisa.
class FullAdhanPreviewScreen extends StatefulWidget {
  final String sessionTitle;
  final Maqam maqam;
  final List<Phrase> phrases;
  final bool isIqomat;
  final PrayerTime? prayerTime;

  const FullAdhanPreviewScreen({
    super.key,
    required this.sessionTitle,
    required this.maqam,
    required this.phrases,
    this.isIqomat = false,
    this.prayerTime,
  });

  @override
  State<FullAdhanPreviewScreen> createState() =>
      _FullAdhanPreviewScreenState();
}

class _FullAdhanPreviewScreenState extends State<FullAdhanPreviewScreen> {
  final _player = AudioPlayerService();
  PlayerState _playerState = PlayerState.stopped;
  SequentialPlaybackSequence? _sequence;

  /// v1.18: agar HAQIQIY uzluksiz yozuv mavjud bo'lsa (1-rejim), shu
  /// yerda saqlanadi. Iqomat uchun hech qachon `null`dan boshqa
  /// bo'lmaydi (hali taqdim etilmagan).
  String? get _singleContinuousFile => widget.isIqomat
      ? null
      : FullMaqamAdhanCatalog.audioFileFor(widget.maqam);

  /// v1.18: 2-rejim uchun — jumlalarni ularning O'Z TARTIBIDA (Azon/
  /// Bomdod ketma-ketligi bilan bir xil), shu maqomga mos audio
  /// fayllarga aylantiradi. Biror jumla uchun bu maqomda fayl mavjud
  /// bo'lmasa, o'sha jumla ketma-ketlikdan chiqarib tashlanadi (xato
  /// bermaydi — shunchaki o'tkazib yuboriladi).
  List<String> get _sequentialFiles {
    if (widget.isIqomat) return const [];
    return widget.phrases
        .map(
          (p) => MaqamReferenceCatalog.variantForMaqam(p.id, widget.maqam)
              ?.audioFile,
        )
        .whereType<String>()
        .toList();
  }

  bool get _hasAnyAudio =>
      _singleContinuousFile != null || _sequentialFiles.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _player.onStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });
    // v1.18: 2-rejimda (ketma-ket ijro), bitta segment tabiiy
    // tugaganda keyingisini avtomatik boshlaymiz.
    _player.onComplete.listen((_) {
      if (!mounted || _singleContinuousFile != null) return;
      final seq = _sequence;
      if (seq == null) return;
      final next = seq.advance();
      if (next != null) {
        _player.playAsset(next);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final single = _singleContinuousFile;
    if (single != null) {
      await _player.playAsset(single);
      return;
    }
    final files = _sequentialFiles;
    if (files.isEmpty) return;
    final seq = _sequence ??= SequentialPlaybackSequence(files);
    final first = seq.start();
    if (first != null) {
      await _player.playAsset(first);
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    _sequence?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = _hasAnyAudio;
    final isPlaying = _playerState == PlayerState.playing;
    final isPaused = _playerState == PlayerState.paused;
    final isSequential = _singleContinuousFile == null && hasAudio;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.maqam.label} — to\'liq namuna')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.graphic_eq,
                size: 72,
                color: hasAudio ? AppTheme.primary : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                widget.maqam.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasAudio
                    ? (isSequential
                        ? 'To\'liq azon namunasi (jumlalar ketma-ket '
                            'ijro etiladi)'
                        : 'To\'liq, uzluksiz azon namunasi')
                    : (widget.isIqomat
                        ? 'To\'liq Iqamah namunasi hali mavjud emas — '
                            'keyinroq qo\'shiladi'
                        : 'To\'liq namuna hali mavjud emas'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: hasAudio && !isPlaying
                        ? (isPaused ? _player.resume : _play)
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    onPressed: hasAudio && isPlaying ? _player.pause : null,
                    icon: const Icon(Icons.pause),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    onPressed:
                        hasAudio && (isPlaying || isPaused) ? _stop : null,
                    icon: const Icon(Icons.stop),
                    iconSize: 32,
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PracticeScreen(
                          title: widget.sessionTitle,
                          phrases: widget.phrases,
                          sessionMaqam: widget.maqam,
                          prayerTime: widget.prayerTime,
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Mashq qilishni boshlash'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
