import 'dart:math' as math;
import 'dart:typed_data';

import '../../models/pitch_frame.dart';
import 'wav_decoder.dart';
import 'yin_pitch_detector.dart';

/// v1.1'dagi PitchAnalyzer._extractPitchContour / _rms metodlaridan
/// SO'ZMA-SO'Z ko'chirilgan umumiy pipeline (freymlash → RMS jimlik
/// tekshiruvi → YIN pitch detection). Algoritm bir bayt ham
/// o'zgartirilmagan — faqat endi bir joyda saqlanadi va ham user
/// recording, ham reference audio uchun bir xil tarzda ishlatiladi
/// (v1.2 talabi: bir xil analyzer pipeline).
class PitchContourExtractor {
  final YinPitchDetector detector;
  final int frameSize;
  final int hopSize;
  final double silenceRmsThreshold;

  const PitchContourExtractor({
    this.detector = const YinPitchDetector(),
    this.frameSize = 2048,
    this.hopSize = 1024,
    this.silenceRmsThreshold = 0.012,
  });

  List<PitchFrame> extract(DecodedAudio audio) {
    final samples = audio.samples;
    final sampleRate = audio.sampleRate;
    final frames = <PitchFrame>[];

    if (samples.length < frameSize) {
      final padded = Float64List(frameSize);
      padded.setRange(0, samples.length, samples);
      final rms = _rms(samples);
      final voiced = rms >= silenceRmsThreshold;
      final result =
          voiced ? detector.detect(padded, sampleRate) : YinResult.unvoiced;
      frames.add(
        PitchFrame(
          timestampMs: 0,
          frequencyHz: result.voiced ? result.frequencyHz : 0,
          voiced: result.voiced,
        ),
      );
      return frames;
    }

    for (int start = 0; start + frameSize <= samples.length; start += hopSize) {
      final frame = Float64List.sublistView(samples, start, start + frameSize);
      final rms = _rms(frame);
      final timestampMs = (start / sampleRate * 1000).round();

      if (rms < silenceRmsThreshold) {
        frames.add(
          PitchFrame(timestampMs: timestampMs, frequencyHz: 0, voiced: false),
        );
        continue;
      }

      final result = detector.detect(frame, sampleRate);
      frames.add(
        PitchFrame(
          timestampMs: timestampMs,
          frequencyHz: result.voiced ? result.frequencyHz : 0,
          voiced: result.voiced,
        ),
      );
    }

    return frames;
  }

  double _rms(Float64List frame) {
    double sum = 0;
    for (final s in frame) {
      sum += s * s;
    }
    return math.sqrt(sum / frame.length);
  }
}
