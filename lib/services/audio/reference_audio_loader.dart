import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../analysis/wav_decoder.dart';

class ReferenceAudioLoadException implements Exception {
  final String message;
  const ReferenceAudioLoadException(this.message);

  @override
  String toString() => 'ReferenceAudioLoadException: $message';
}

/// Reference audio assetini (assets/audio/...) baytlar sifatida o'qiydi
/// va mavjud [WavDecoder] orqali dekodlaydi.
///
/// MUHIM: v1.2 pipeline'i faqat WAV/PCM16 formatini tushunadi (xuddi
/// foydalanuvchi recordingi kabi). Shuning uchun reference audio
/// fayllari ham WAV formatida bo'lishi kerak — bu ReferenceAudioChecker
/// bilan birga ishlaydi: avval fayl mavjudligini tekshiramiz, keyin uni
/// shu klass orqali yuklab, WAV sifatida dekodlashga urinib ko'ramiz.
/// Format noto'g'ri bo'lsa, fake natija bermasdan aniq xato qaytaramiz.
class ReferenceAudioLoader {
  final WavDecoder _decoder;

  const ReferenceAudioLoader({WavDecoder decoder = const WavDecoder()})
      : _decoder = decoder;

  Future<DecodedAudio> load(String assetFileName) async {
    final ByteData data;
    try {
      data = await rootBundle.load('assets/audio/$assetFileName');
    } catch (_) {
      throw const ReferenceAudioLoadException(
        'Reference audio fayli assets ichida topilmadi',
      );
    }

    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    try {
      return _decoder.decodeBytes(bytes);
    } on WavDecodeException catch (e) {
      throw ReferenceAudioLoadException(
        'Reference audio WAV formatida emas yoki buzilgan: ${e.message}',
      );
    }
  }
}
