import 'dart:io';
import 'dart:typed_data';

/// WAV faylni o'qib, PCM namunalarni -1.0..1.0 oralig'idagi double
/// qiymatlarga aylantiradi.
///
/// Faqat PCM16 (16-bit) WAV formatini qo'llab-quvvatlaydi — bu
/// AudioRecorderService yozadigan format bilan bir xil, shuning uchun
/// alohida audio-codec (masalan, AAC decoder) kerak emas.
class DecodedAudio {
  final Float64List samples;
  final int sampleRate;
  final int channels;

  const DecodedAudio({
    required this.samples,
    required this.sampleRate,
    required this.channels,
  });

  double get durationSeconds =>
      channels == 0 || sampleRate == 0 ? 0 : samples.length / sampleRate;
}

class WavDecodeException implements Exception {
  final String message;
  const WavDecodeException(this.message);

  @override
  String toString() => 'WavDecodeException: $message';
}

class WavDecoder {
  const WavDecoder();

  Future<DecodedAudio> decodeFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const WavDecodeException('Audio fayl topilmadi');
    }
    final bytes = await file.readAsBytes();
    return decodeBytes(bytes);
  }

  DecodedAudio decodeBytes(Uint8List bytes) {
    if (bytes.length < 44) {
      throw const WavDecodeException('Fayl juda kichik, WAV emas');
    }

    final data = ByteData.sublistView(bytes);

    // RIFF header tekshiruvi.
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') {
      throw const WavDecodeException('Fayl WAV formatida emas');
    }

    int channels = 1;
    int sampleRate = 16000;
    int bitsPerSample = 16;
    int audioFormat = 1; // 1 = PCM

    int offset = 12;
    int? dataOffset;
    int? dataLength;

    // Chunklarni ("fmt ", "data", ...) topib o'qiymiz — chunk tartibi
    // kafolatlanmagan, shuning uchun to'liq skan qilamiz.
    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      final chunkDataStart = offset + 8;

      if (chunkId == 'fmt ') {
        audioFormat = data.getUint16(chunkDataStart, Endian.little);
        channels = data.getUint16(chunkDataStart + 2, Endian.little);
        sampleRate = data.getUint32(chunkDataStart + 4, Endian.little);
        bitsPerSample = data.getUint16(chunkDataStart + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = chunkDataStart;
        dataLength = chunkSize;
      }

      // Chunk hajmi toq bo'lsa, WAV spetsifikatsiyasi 1 bayt padding talab
      // qiladi.
      offset = chunkDataStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
    }

    if (dataOffset == null || dataLength == null) {
      throw const WavDecodeException('WAV "data" chunk topilmadi');
    }
    if (audioFormat != 1 || bitsPerSample != 16) {
      throw WavDecodeException(
        'Faqat PCM16 WAV qo\'llab-quvvatlanadi (format=$audioFormat, '
        'bits=$bitsPerSample)',
      );
    }

    final rawEnd = dataOffset + dataLength;
    final safeEnd = rawEnd > bytes.length ? bytes.length : rawEnd;
    final sampleCountAllChannels = (safeEnd - dataOffset) ~/ 2;
    final frameCount = sampleCountAllChannels ~/ channels;

    // Ko'p kanalli bo'lsa, kanallar bo'yicha o'rtachasini olib mono
    // signalga aylantiramiz — pitch detection uchun mono yetarli.
    final mono = Float64List(frameCount);
    for (int i = 0; i < frameCount; i++) {
      double sum = 0;
      for (int c = 0; c < channels; c++) {
        final sampleIndex = dataOffset + (i * channels + c) * 2;
        final raw = data.getInt16(sampleIndex, Endian.little);
        sum += raw / 32768.0;
      }
      mono[i] = sum / channels;
    }

    return DecodedAudio(
      samples: mono,
      sampleRate: sampleRate,
      channels: 1,
    );
  }
}
