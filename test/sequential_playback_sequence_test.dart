import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/services/audio/sequential_playback_sequence.dart';

void main() {
  group('SequentialPlaybackSequence', () {
    test('bo\'sh ro\'yxat uchun isEmpty=true, current=null', () {
      final seq = SequentialPlaybackSequence([]);
      expect(seq.isEmpty, isTrue);
      expect(seq.current, isNull);
    });

    test('start() birinchi faylni qaytaradi', () {
      final seq = SequentialPlaybackSequence(['a.wav', 'b.wav', 'c.wav']);
      expect(seq.start(), 'a.wav');
      expect(seq.current, 'a.wav');
      expect(seq.currentIndex, 0);
    });

    test('advance() ketma-ket keyingi fayllarga o\'tadi', () {
      final seq = SequentialPlaybackSequence(['a.wav', 'b.wav', 'c.wav']);
      seq.start();

      expect(seq.advance(), 'b.wav');
      expect(seq.advance(), 'c.wav');
    });

    test(
        'oxirgi fayldan keyin advance() null qaytaradi, isFinished=true',
        () {
      final seq = SequentialPlaybackSequence(['a.wav', 'b.wav']);
      seq.start();
      seq.advance(); // b.wav
      final afterLast = seq.advance();

      expect(afterLast, isNull);
      expect(seq.isFinished, isTrue);
      expect(seq.current, isNull);
    });

    test('reset() ketma-ketlikni boshiga qaytaradi', () {
      final seq = SequentialPlaybackSequence(['a.wav', 'b.wav', 'c.wav']);
      seq.start();
      seq.advance();
      seq.advance();
      expect(seq.isFinished, isTrue);

      seq.reset();
      expect(seq.currentIndex, 0);
      expect(seq.current, 'a.wav');
    });

    test('bitta fayldan iborat ketma-ketlik to\'g\'ri ishlaydi', () {
      final seq = SequentialPlaybackSequence(['only.wav']);
      expect(seq.start(), 'only.wav');
      expect(seq.advance(), isNull);
      expect(seq.isFinished, isTrue);
    });

    test(
        'start() ikkinchi marta chaqirilsa, qaytadan boshidan boshlaydi',
        () {
      final seq = SequentialPlaybackSequence(['a.wav', 'b.wav']);
      seq.start();
      seq.advance();
      expect(seq.currentIndex, 1);

      final restarted = seq.start();
      expect(restarted, 'a.wav');
      expect(seq.currentIndex, 0);
    });
  });
}
