import 'dart:math' as math;
import 'dart:typed_data';

/// Testlar uchun minimal, to'g'ri formatdagi WAV (PCM16, mono) bayt
/// massivini generatsiya qiladi. [toneHz] null bo'lsa — to'liq jimlik
/// (barcha namunalar 0), aks holda shu chastotali sinusoida yoziladi.
Uint8List buildTestWav({
  required int sampleRate,
  required double durationSeconds,
  double? toneHz,
  double amplitude = 0.6,
}) {
  final frameCount = (sampleRate * durationSeconds).round();
  final dataLength = frameCount * 2; // 16-bit = 2 bayt/namuna

  final buffer = ByteData(44 + dataLength);

  void writeString(int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  buffer.setUint32(4, 36 + dataLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little); // fmt chunk size
  buffer.setUint16(20, 1, Endian.little); // PCM
  buffer.setUint16(22, 1, Endian.little); // mono
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  buffer.setUint16(32, 2, Endian.little); // block align
  buffer.setUint16(34, 16, Endian.little); // bits per sample
  writeString(36, 'data');
  buffer.setUint32(40, dataLength, Endian.little);

  for (int i = 0; i < frameCount; i++) {
    double sampleValue;
    if (toneHz == null) {
      sampleValue = 0;
    } else {
      sampleValue =
          amplitude * math.sin(2 * math.pi * toneHz * i / sampleRate);
    }
    var intSample = (sampleValue * 32767).round();
    if (intSample > 32767) intSample = 32767;
    if (intSample < -32768) intSample = -32768;
    buffer.setInt16(44 + i * 2, intSample, Endian.little);
  }

  return buffer.buffer.asUint8List();
}
