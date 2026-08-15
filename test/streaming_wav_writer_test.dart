import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/services/analysis/wav_decoder.dart';
import 'package:azon_trainer/services/audio/streaming_wav_writer.dart';

/// v1.14: MUHIM round-trip test — `StreamingWavWriter` (yangi) orqali
/// yozilgan fayl, `WavDecoder` (v1.3'dan tasdiqlangan, o'zgartirilmagan)
/// orqali TO'G'RI o'qilishini isbotlaydi.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('streaming_wav_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StreamingWavWriter — WavDecoder bilan round-trip moslik', () {
    test('yozilgan WAV fayl WavDecoder orqali xatosiz o\'qiladi', () async {
      final writer = StreamingWavWriter(sampleRate: 16000, channels: 1);

      final sampleCount = 8000;
      final bytes = ByteData(sampleCount * 2);
      for (int i = 0; i < sampleCount; i++) {
        final t = i / 16000;
        final value = 0.5 * math.sin(2 * math.pi * 200 * t) * 32767;
        bytes.setInt16(i * 2, value.round(), Endian.little);
      }
      final allBytes = bytes.buffer.asUint8List();

      writer.addBytes(allBytes.sublist(0, 8000));
      writer.addBytes(allBytes.sublist(8000));

      final path = '${tempDir.path}/test_stream.wav';
      final duration = await writer.finalizeToFile(path);

      expect(duration.inMilliseconds, closeTo(500, 5));

      final decoded = await const WavDecoder().decodeFile(path);
      expect(decoded.sampleRate, 16000);
      expect(decoded.channels, 1);
      expect(decoded.samples.length, sampleCount);
      expect(decoded.durationSeconds, closeTo(0.5, 0.01));

      for (final i in [0, 100, 4000, 7999]) {
        final expected =
            allBytes.buffer.asByteData().getInt16(i * 2, Endian.little) /
                32768.0;
        expect(decoded.samples[i], closeTo(expected, 0.0001));
      }
    });

    test(
        'bo\'sh (hech qanday bayt qo\'shilmagan) yozuv ham xato bermaydi',
        () async {
      final writer = StreamingWavWriter(sampleRate: 16000);
      final path = '${tempDir.path}/empty.wav';

      final duration = await writer.finalizeToFile(path);
      expect(duration, Duration.zero);

      final decoded = await const WavDecoder().decodeFile(path);
      expect(decoded.samples, isEmpty);
    });

    test('currentDuration yozish jarayonida to\'g\'ri hisoblanadi', () {
      final writer = StreamingWavWriter(sampleRate: 16000);
      expect(writer.currentDuration, Duration.zero);

      final oneSecondOfSilence = Uint8List(16000 * 2);
      writer.addBytes(oneSecondOfSilence);

      expect(writer.currentDuration.inMilliseconds, closeTo(1000, 5));
    });
  });
}
