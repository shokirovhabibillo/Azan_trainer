import 'package:record_platform_interface/record_platform_interface.dart';

/// Local stub replacement for the real `record_linux` package.
///
/// This app is Android-only. The upstream `record` package facade
/// unconditionally references `record_linux` regardless of the
/// actual build target, so the Dart compiler must be able to fully
/// type-check this class even though it is never instantiated or
/// used at runtime on Android.
///
/// At the time this was written, the published `record_linux`
/// package versions were out of sync with `record_platform_interface`
/// (missing implementations for newer abstract members such as
/// `startStream`), and no sandbox internet access was available to
/// determine a matching version pair. Rather than guess further
/// version numbers, this stub uses the Dart `noSuchMethod` override
/// to satisfy ALL abstract members of [RecordPlatform] automatically,
/// regardless of their exact signatures. Any accidental real
/// invocation (which should never happen on Android) throws a clear
/// [UnsupportedError] instead of silently doing nothing.
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
