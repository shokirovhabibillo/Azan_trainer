import 'package:flutter/services.dart' show rootBundle;

/// Reference audio fayli assets/audio/ ichida mavjudligini tekshiradi.
///
/// Bu Flutter'ning rootBundle API'siga tayanadi (widget yoki
/// BuildContext emas), shuning uchun analyzer qatlamida ishlatilishi
/// UI bilan aralashuv hisoblanmaydi — sof "resurs mavjudmi?" tekshiruvi.
class ReferenceAudioChecker {
  const ReferenceAudioChecker();

  Future<bool> exists(String assetFileName) async {
    if (assetFileName.isEmpty) return false;
    try {
      await rootBundle.load('assets/audio/$assetFileName');
      return true;
    } catch (_) {
      return false;
    }
  }
}
