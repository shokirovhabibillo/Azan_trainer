import 'package:record_platform_interface/record_platform_interface.dart';

class RecordLinux extends RecordPlatform {
  static void registerWith() {
    RecordPlatform.instance = RecordLinux();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError(
      'record_linux stub: Linux audio recording is not implemented in '
      'this Android-only build. This should never be called at runtime.',
    );
  }
}
