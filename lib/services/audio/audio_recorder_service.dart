import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/constants.dart';

/// Mikrofon orqali audio yozib olishni boshqaradi va faylni
/// qurilma xotirasiga saqlaydi.
///
/// UI'dan mustaqil: hech qanday widget yoki BuildContext bilan ishlamaydi.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  bool get isPermissionPermanentlyDenied =>
      false; // permission_handler holatini UI darajasida ham tekshirish mumkin

  /// v1.1: recording endi WAV/PCM16 formatida yoziladi (m4a emas).
  /// Sabab: PitchAnalyzer signalni to'g'ridan-to'g'ri PCM sifatida
  /// o'qishi kerak. WAV konteyneri PCM'ni o'z ichiga oladi, shuning
  /// uchun alohida AAC→PCM decode bosqichiga ehtiyoj qolmaydi.
  static const int sampleRate = 16000;
  static const int numChannels = 1;

  Future<void> start({required String phraseId}) async {
    final granted = await hasPermission();
    if (!granted) {
      throw StateError('Mikrofonga ruxsat berilmadi');
    }

    final dir = await _recordingsDirectory();
    final fileName =
        '${phraseId}_${DateTime.now().millisecondsSinceEpoch}.wav';
    final path = '${dir.path}/$fileName';

    _startedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: sampleRate,
        numChannels: numChannels,
      ),
      path: path,
    );
  }

  /// Yozishni to'xtatadi va saqlangan fayl yo'lini qaytaradi.
  /// Yozib bo'lingan audio davomiyligini ham qaytaradi (sekundlarda).
  Future<RecordingOutcome?> stop() async {
    final path = await _recorder.stop();
    if (path == null) return null;

    final duration = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);
    _startedAt = null;

    return RecordingOutcome(filePath: path, duration: duration);
  }

  Future<bool> get isRecording => _recorder.isRecording();

  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      final path = await _recorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
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
    _recorder.dispose();
  }
}

class RecordingOutcome {
  final String filePath;
  final Duration duration;

  const RecordingOutcome({required this.filePath, required this.duration});
}
