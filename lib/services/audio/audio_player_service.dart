import 'package:audioplayers/audioplayers.dart';

/// Reference (namuna) audio va foydalanuvchi yozgan audioni ijro etadi.
/// UI'dan mustaqil.
///
/// v1.3: Play/Pause/Stop uchun to'liq boshqaruv qo'shildi (talab #5).
/// Bu klass faqat IJRO ETISH (playback) uchun — audioplayers paketi
/// orqali istalgan formatni (shu jumladan WAV) o'ynata oladi. Bu
/// pitch-tahlil pipeline'idan (WavDecoder, faqat WAV/PCM16) MUSTAQIL:
/// tahlil har doim qat'iy WAV dekoderidan o'tadi, ijro esa audioplayers
/// orqali amalga oshadi — ikkalasi bir-biriga ta'sir qilmaydi.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  /// Ijro holati oqimi — UI Play/Pause tugmasini to'g'ri holatda
  /// ko'rsatishi uchun ishlatilishi mumkin.
  Stream<PlayerState> get onStateChanged => _player.onPlayerStateChanged;

  /// v1.18: bitta audio segmenti TABIIY tugaganda signal beradi
  /// (foydalanuvchi Stop bosgani uchun emas). Ketma-ket avtomatik
  /// ijro etish (masalan, "to'liq azon" — jumlalarni birlashtirmasdan,
  /// birin-ketin avtomatik ijro etib) uchun ishlatiladi. Mavjud
  /// Play/Pause/Stop xatti-harakatiga hech qanday ta'sir qilmaydi —
  /// bu faqat QO'SHIMCHA, kuzatuvchi oqim.
  Stream<void> get onComplete => _player.onPlayerComplete;

  Future<bool> playAsset(String assetFileName) async {
    try {
      await _player.play(AssetSource('audio/$assetFileName'));
      return true;
    } catch (_) {
      // Fayl assets/audio/ ichida mavjud emas — UI buni ochiq ko'rsatadi,
      // hech qanday fallback audio ijro etilmaydi.
      return false;
    }
  }

  Future<void> playFile(String filePath) async {
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.resume();

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}
