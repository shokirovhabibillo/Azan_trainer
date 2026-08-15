import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/constants.dart';
import '../analysis/realtime_pitch_analyzer.dart';
import '../analysis/voice_level_analyzer.dart';
import 'audio_recorder_service.dart';
import 'streaming_wav_writer.dart';

/// v1.14: real-vaqt pitch/volume monitoring bilan yozib olish.
///
/// MUHIM (ochiq eslatma): `record` paketining oqim (stream) API'si
/// ushbu sandbox muhitida internet aloqasi yo'qligi sababli paket
/// manba kodidan bevosita tasdiqlanmadi — faqat umumiy, ishonchli
/// bilim asosida ishlatilgan. Shu sababli, agar oqim boshlanishida
/// (`startStream`) XATOLIK yuz bersa, bu klass AVTOMATIK ravishda
/// eski, allaqachon tasdiqlangan fayl-asosidagi
/// `AudioRecorderService`ga o'tadi (fallback) — foydalanuvchi bu
/// holatda real-vaqt grafigini ko'rmaydi, lekin ovoz yozish va
/// keyingi (post-hoc) tahlil baribir muammosiz ishlayveradi. Ya'ni,
/// bu yangi qatlamdagi noaniqlik ASOSIY (eski, tasdiqlangan) recording
/// funksiyasini hech qachon buzmaydi.
class RealtimeAudioRecorderService {
  static const int sampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();
  final _fallbackRecorder = AudioRecorderService();

  late RealtimePitchAnalyzer _pitchAnalyzer;
  final _levelAnalyzer = VoiceLevelAnalyzer();
  StreamingWavWriter? _writer;
  StreamSubscription<Uint8List>? _subscription;

  final _pitchController =
      StreamController<RealtimePitchSample>.broadcast();
  final _levelController = StreamController<VoiceLevelSample>.broadcast();

  String? _pendingPath;
  DateTime? _startedAt;
  bool _usingFallback = false;

  /// Real-vaqt pitch namunalari oqimi. Fallback rejimida (streaming
  /// ishlamagan holatda) bu oqim bo'sh qoladi — hech narsa
  /// yubormaydi, lekin xato ham bermaydi.
  Stream<RealtimePitchSample> get pitchStream => _pitchController.stream;

  /// Real-vaqt ovoz darajasi oqimi. Xuddi shu fallback qoidasi.
  Stream<VoiceLevelSample> get levelStream => _levelController.stream;

  /// Joriy sessiya real-vaqt monitoring bilan ishlayotganmi (`true`),
  /// yoki eski, oddiy fayl-asosidagi rejimga o'tib ketganmi (`false`)
  /// — UI shu orqali "jonli grafik ko'rsatilmayapti" holatini bilishi
  /// mumkin.
  bool get isUsingRealtimeMonitoring => !_usingFallback;

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start({required String phraseId}) async {
    final granted = await hasPermission();
    if (!granted) {
      throw StateError('Mikrofonga ruxsat berilmadi');
    }

    _pitchAnalyzer = RealtimePitchAnalyzer(sampleRate: sampleRate);
    _usingFallback = false;

    try {
      final dir = await _recordingsDirectory();
      final fileName =
          '${phraseId}_${DateTime.now().millisecondsSinceEpoch}.wav';
      _pendingPath = '${dir.path}/$fileName';
      _writer = StreamingWavWriter(sampleRate: sampleRate);
      _startedAt = DateTime.now();

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );

      _subscription = stream.listen(
        _handleChunk,
        onError: (_) {
          // Oqim davomida xato yuz bersa ham, yozib olingan qism
          // (agar bo'lsa) yo'qolmaydi — stop() chaqirilganda mavjud
          // baytlar bilan fayl yakunlanadi.
        },
      );
    } catch (_) {
      // Streaming ishga tushmadi — eski, tasdiqlangan usulga o'tamiz.
      _usingFallback = true;
      _writer = null;
      _pendingPath = null;
      await _fallbackRecorder.start(phraseId: phraseId);
    }
  }

  void _handleChunk(Uint8List chunk) {
    _writer?.addBytes(chunk);
    for (final sample in _pitchAnalyzer.addBytes(chunk)) {
      if (!_pitchController.isClosed) _pitchController.add(sample);
    }
    if (!_levelController.isClosed) {
      _levelController.add(_levelAnalyzer.analyze(chunk));
    }
  }

  Future<RecordingOutcome?> stop() async {
    if (_usingFallback) {
      return _fallbackRecorder.stop();
    }

    await _subscription?.cancel();
    _subscription = null;
    try {
      await _recorder.stop();
    } catch (_) {
      // Allaqachon to'xtagan yoki xato — baribir mavjud baytlarni
      // faylga yozishga urinamiz.
    }

    final writer = _writer;
    final path = _pendingPath;
    _writer = null;
    _pendingPath = null;

    if (writer == null || path == null || writer.bytesWritten == 0) {
      return null;
    }

    final duration = await writer.finalizeToFile(path);
    return RecordingOutcome(filePath: path, duration: duration);
  }

  Future<void> cancel() async {
    if (_usingFallback) {
      await _fallbackRecorder.cancel();
      return;
    }
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    _writer = null;
    _pendingPath = null;
    _startedAt = null;
  }

  Future<Directory> _recordingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${appDir.path}/${AppConstants.recordingsFolderName}',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  void dispose() {
    _subscription?.cancel();
    _pitchController.close();
    _levelController.close();
    _recorder.dispose();
    _fallbackRecorder.dispose();
  }
}
