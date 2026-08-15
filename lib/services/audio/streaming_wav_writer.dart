import 'dart:io';
import 'dart:typed_data';

/// v1.14: mikrofon oqimidan kelayotgan RAW PCM16 baytlarni to'plab,
/// yozish tugagach standart WAV (RIFF/fmt /data) headerini biriktirib
/// faylga yozadi.
///
/// MUHIM: bu yerda yaratiladigan WAV format `wav_decoder.dart`
/// (himoyalangan, o'zgartirilmagan) kutayotgan formatga BAYT
/// DARAJASIDA mos — PCM (format=1), 16-bit, mono. Shuning uchun
/// real-vaqt oqimi orqali yozilgan fayl xuddi eski
/// `AudioRecorderService` yozgan fayl kabi, mavjud
/// `PitchAnalyzer`/`DurationAnalyzer` orqali muammosiz tahlil
/// qilinadi — alohida/soddalashtirilgan tahlil yo'li yaratilmagan.
class StreamingWavWriter {
  final int sampleRate;
  final int channels;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);

  StreamingWavWriter({required this.sampleRate, this.channels = 1});

  void addBytes(Uint8List bytes) {
    _pcmBuffer.add(bytes);
  }

  int get bytesWritten => _pcmBuffer.length;

  /// Taxminiy davomiylik — hozirgacha to'plangan bayt soniga qarab.
  Duration get currentDuration {
    final sampleCount = _pcmBuffer.length ~/ 2 ~/ channels;
    final seconds = sampleRate == 0 ? 0 : sampleCount / sampleRate;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// To'plangan PCM baytlarni standart WAV header bilan faylga yozadi.
  Future<Duration> finalizeToFile(String path) async {
    final pcmBytes = _pcmBuffer.takeBytes();
    final header = _buildWavHeader(
      dataLength: pcmBytes.length,
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: 16,
    );

    final file = File(path);
    final sink = file.openWrite();
    sink.add(header);
    sink.add(pcmBytes);
    await sink.flush();
    await sink.close();

    final sampleCount = pcmBytes.length ~/ 2 ~/ channels;
    final seconds = sampleRate == 0 ? 0 : sampleCount / sampleRate;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  Uint8List _buildWavHeader({
    required int dataLength,
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final riffChunkSize = 36 + dataLength;

    final header = ByteData(44);
    void writeAscii(int offset, String text) {
      for (int i = 0; i < text.length; i++) {
        header.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, riffChunkSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little); // audioFormat = PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    return header.buffer.asUint8List();
  }
}
