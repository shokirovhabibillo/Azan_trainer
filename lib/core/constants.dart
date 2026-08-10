/// Ilova bo'yicha umumiy konstantalar.
class AppConstants {
  AppConstants._();

  static const String appName = 'Azon Trainer';

  /// Foydalanuvchi yozgan audiolar shu papka ichida saqlanadi
  /// (path_provider orqali qurilma xotirasida).
  static const String recordingsFolderName = 'azon_trainer_recordings';

  /// Reference (namuna) audiolar shu assets papkasidan o'qiladi.
  /// Hozircha fayllar joylashtirilmagan — StorageService fayl yo'qligini
  /// aniqlab, UI'da ogohlantiradi (fake audio bilan almashtirilmaydi).
  static const String referenceAudioAssetPath = 'assets/audio/';
}
