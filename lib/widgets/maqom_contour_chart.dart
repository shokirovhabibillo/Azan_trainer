// maqom_contour_chart.dart
//
// Renders a schematic pitch-contour line for one azon phrase, in the visual
// style of the reference sketch: a smooth red line for the melodic shape,
// with a small zigzag ornament drawn over any detected "trill" (zulzula)
// zone, and the Arabic phrase label centered underneath.
//
// Data source: assets/maqom_contours.json (produced by analyze_maqoms_v2.py)
// Each phrase entry:
//   { "id", "labelArabic", "labelLatin", "fajrOnly", "durationSec",
//     "points": [ {"t": seconds, "semitone": value}, ... ],
//     "trillZones": [ {"start": seconds, "end": seconds, "amplitude": semis}, ... ] }
//
// This widget does NOT touch pitch-detection internals (YIN, PitchContourExtractor,
// ReferencePitchComparator, WavDecoder, DurationAnalyzer) — it only consumes
// already-precomputed contour points bundled as a static asset.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class MaqomPoint {
  final double t;
  final double semitone;
  MaqomPoint(this.t, this.semitone);
}

class TrillZone {
  final double start;
  final double end;
  final double amplitude;
  TrillZone(this.start, this.end, this.amplitude);
}

class MaqomPhrase {
  final String id;
  final String labelArabic;
  final String labelLatin;
  final bool fajrOnly;
  final double durationSec;
  final List<MaqomPoint> points;
  final List<TrillZone> trillZones;

  MaqomPhrase({
    required this.id,
    required this.labelArabic,
    required this.labelLatin,
    required this.fajrOnly,
    required this.durationSec,
    required this.points,
    required this.trillZones,
  });

  factory MaqomPhrase.fromJson(Map<String, dynamic> j) {
    return MaqomPhrase(
      id: j['id'],
      labelArabic: j['labelArabic'],
      labelLatin: j['labelLatin'],
      fajrOnly: j['fajrOnly'] ?? false,
      durationSec: (j['durationSec'] as num).toDouble(),
      points: (j['points'] as List)
          .map((p) => MaqomPoint((p['t'] as num).toDouble(), (p['semitone'] as num).toDouble()))
          .toList(),
      trillZones: (j['trillZones'] as List)
          .map((z) => TrillZone((z['start'] as num).toDouble(), (z['end'] as num).toDouble(),
              (z['amplitude'] as num).toDouble()))
          .toList(),
    );
  }
}

class MaqomData {
  final String maqom;
  final double tonicHz;
  final List<MaqomPhrase> phrases;
  MaqomData(this.maqom, this.tonicHz, this.phrases);

  factory MaqomData.fromJson(Map<String, dynamic> j) {
    return MaqomData(
      j['maqom'],
      (j['tonicHz'] as num).toDouble(),
      (j['phrases'] as List).map((p) => MaqomPhrase.fromJson(p)).toList(),
    );
  }
}

/// Loads assets/maqom_contours.json once and exposes per-maqom data.
class MaqomContourRepository {
  static final Map<String, MaqomData> _cache = {};

  static Future<MaqomData> load(String maqomId) async {
    if (_cache.containsKey(maqomId)) return _cache[maqomId]!;
    final raw = await rootBundle.loadString('assets/maqom_contours.json');
    final Map<String, dynamic> all = json.decode(raw);
    for (final entry in all.entries) {
      _cache[entry.key] = MaqomData.fromJson(entry.value);
    }
    return _cache[maqomId]!;
  }
}

/// A single phrase's schematic contour: smooth line + trill zigzag + label.
///
/// v1.26: ikkita QO'SHIMCHA, ixtiyoriy qatlam qo'shildi:
///   - [cursorTimeSec]: agar berilsa, shu vaqt nuqtasida vertikal
///     "jonli kursor" chiziladi (to'liq namuna ijrosi bilan
///     sinxronlash uchun).
///   - [liveUserPoints]: agar berilsa, mavjud (statik, JSON'dan
///     kelgan) reference egri chizig'i USTIGA, foydalanuvchi
///     ovozining JONLI konturi ikkinchi rang bilan chiziladi (mashq
///     ekranida "namuna ustida shakllanish" effekti uchun).
class MaqomPhraseChart extends StatelessWidget {
  final MaqomPhrase phrase;
  final Color lineColor;
  final double height;
  final bool showLatinLabel;
  final double? cursorTimeSec;
  final List<MaqomPoint>? liveUserPoints;
  final Color liveUserColor;

  const MaqomPhraseChart({
    super.key,
    required this.phrase,
    this.lineColor = const Color(0xFFDC2626), // matches reference sketch red
    this.height = 160,
    this.showLatinLabel = true,
    this.cursorTimeSec,
    this.liveUserPoints,
    this.liveUserColor = const Color(0xFF2563EB), // ko'k — foydalanuvchi ovozi
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _ContourPainter(
              phrase: phrase,
              lineColor: lineColor,
              cursorTimeSec: cursorTimeSec,
              liveUserPoints: liveUserPoints,
              liveUserColor: liveUserColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          phrase.labelArabic,
          style: const TextStyle(fontSize: 20, fontFamily: 'Amiri', color: Colors.black87),
          textDirection: TextDirection.rtl,
        ),
        if (showLatinLabel)
          Text(
            phrase.labelLatin,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
      ],
    );
  }
}

class _ContourPainter extends CustomPainter {
  final MaqomPhrase phrase;
  final Color lineColor;
  final double? cursorTimeSec;
  final List<MaqomPoint>? liveUserPoints;
  final Color liveUserColor;

  _ContourPainter({
    required this.phrase,
    required this.lineColor,
    this.cursorTimeSec,
    this.liveUserPoints,
    this.liveUserColor = const Color(0xFF2563EB),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (phrase.points.isEmpty) return;
    // v1.26: jonli foydalanuvchi nuqtalari reference davomiyligidan
    // uzunroq bo'lishi mumkin (masalan, sekinroq aytilsa) — chizmani
    // widget chegarasidan tashqariga "toshib ketishidan" himoya.
    canvas.clipRect(Offset.zero & size);

    final minT = phrase.points.first.t;
    final maxT = phrase.points.last.t;
    double minY = phrase.points.map((p) => p.semitone).reduce(math.min) - 1;
    double maxY = phrase.points.map((p) => p.semitone).reduce(math.max) + 1;
    // v1.26: agar jonli foydalanuvchi nuqtalari ham chizilsa, ular
    // reference diapazonidan tashqariga chiqib ketmasligi uchun
    // Y o'qini kengaytiramiz (aks holda foydalanuvchi ovozi chetga
    // "kesilib" qolishi mumkin edi).
    if (liveUserPoints != null && liveUserPoints!.isNotEmpty) {
      final liveMin = liveUserPoints!.map((p) => p.semitone).reduce(math.min);
      final liveMax = liveUserPoints!.map((p) => p.semitone).reduce(math.max);
      minY = math.min(minY, liveMin - 1);
      maxY = math.max(maxY, liveMax + 1);
    }

    double xOf(double t) => (maxT == minT) ? 0 : (t - minT) / (maxT - minT) * size.width;
    double yOf(double s) =>
        (maxY == minY) ? size.height / 2 : size.height - (s - minY) / (maxY - minY) * size.height;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final pts = phrase.points;
    // Convert data points to a smooth, free-flowing curve using a
    // Catmull-Rom spline (matches the reference sketch's oval, organic
    // look far better than straight/quadratic segments through sparse
    // simplified points).
    final path = _catmullRomPath(
      pts.map((p) => Offset(xOf(p.t), yOf(p.semitone))).toList(),
    );

    canvas.drawPath(path, linePaint);

    // Draw a small decorative zigzag "trill" glyph on top of the curve at
    // each detected zulzula zone, rather than deforming the main line.
    for (final z in phrase.trillZones) {
      if (z.end - z.start < 0.15) continue;
      final midT = (z.start + z.end) / 2;
      // find the curve's y at midT via nearest data points (linear approx)
      double yAt = pts.last.semitone;
      for (int i = 0; i < pts.length - 1; i++) {
        if (midT >= pts[i].t && midT <= pts[i + 1].t) {
          final span = (pts[i + 1].t - pts[i].t);
          final frac = span == 0 ? 0.0 : (midT - pts[i].t) / span;
          yAt = pts[i].semitone + (pts[i + 1].semitone - pts[i].semitone) * frac;
          break;
        }
      }
      _drawTrillGlyph(canvas, Offset(xOf(midT), yOf(yAt)), size.height * 0.045, linePaint);
    }

    // v1.26: jonli foydalanuvchi ovozi — ikkinchi (ko'k) egri chiziq,
    // reference (qizil) ustiga qo'yiladi. Faqat "voiced" (aniqlangan)
    // nuqtalar chiziladi — jimlik/aniqlanmagan joylarda chiziq
    // uzilib turadi (soxta tekislik ko'rsatilmaydi).
    if (liveUserPoints != null && liveUserPoints!.isNotEmpty) {
      final userPaint = Paint()
        ..color = liveUserColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;

      Offset? prev;
      for (final p in liveUserPoints!) {
        final point = Offset(xOf(p.t), yOf(p.semitone));
        if (prev != null) {
          canvas.drawLine(prev, point, userPaint);
        }
        prev = point;
      }
      // Joriy (oxirgi) nuqtada kichik doira — "hozir shu yerdaman".
      final last = liveUserPoints!.last;
      canvas.drawCircle(
        Offset(xOf(last.t), yOf(last.semitone)),
        4.5,
        Paint()..color = liveUserColor,
      );
    }

    // v1.26: jonli ijro kursori — to'liq namuna ijrosi bilan
    // sinxronlangan vertikal chiziq.
    final cursor = cursorTimeSec;
    if (cursor != null && cursor >= minT && cursor <= maxT) {
      final cursorPaint = Paint()
        ..color = Colors.black54
        ..strokeWidth = 2;
      final x = xOf(cursor);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), cursorPaint);
      canvas.drawCircle(Offset(x, 0), 4, Paint()..color = Colors.black54);
    }
  }

  /// Catmull-Rom -> cubic Bezier conversion for a smooth path through all
  /// given points (no overshoot beyond local neighbors, unlike a global
  /// natural cubic spline).
  Path _catmullRomPath(List<Offset> p) {
    final path = Path();
    if (p.isEmpty) return path;
    if (p.length < 3) {
      path.moveTo(p.first.dx, p.first.dy);
      for (final pt in p.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      return path;
    }
    path.moveTo(p.first.dx, p.first.dy);
    for (int i = 0; i < p.length - 1; i++) {
      final p0 = i == 0 ? p[i] : p[i - 1];
      final p1 = p[i];
      final p2 = p[i + 1];
      final p3 = (i + 2 < p.length) ? p[i + 2] : p2;

      final b1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final b2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);

      path.cubicTo(b1.dx, b1.dy, b2.dx, b2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawTrillGlyph(Canvas canvas, Offset center, double amp, Paint basePaint) {
    final glyph = Path();
    const teeth = 3;
    final w = amp * 2.6;
    glyph.moveTo(center.dx - w, center.dy);
    for (int k = 1; k <= teeth * 2; k++) {
      final dx = -w + (2 * w) * (k / (teeth * 2));
      final dy = (k.isOdd ? -amp : amp);
      glyph.lineTo(center.dx + dx, center.dy + dy);
    }
    final glyphPaint = Paint()
      ..color = basePaint.color
      ..strokeWidth = basePaint.strokeWidth * 0.85
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(glyph, glyphPaint);
  }

  @override
  bool shouldRepaint(covariant _ContourPainter oldDelegate) =>
      oldDelegate.phrase != phrase ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.cursorTimeSec != cursorTimeSec ||
      oldDelegate.liveUserPoints != liveUserPoints;
}

/// Full maqom view: all phrases laid out left-to-right in azon order,
/// matching the reference image's multi-segment layout.
///
/// v1.26: [activePhraseId] + [activePhrasePositionSec] — agar berilsa,
/// mos jumla panelida jonli ijro kursori ko'rsatiladi (to'liq namuna
/// Play/Pause/Stop bilan sinxronlangan holda).
class MaqomFullContourView extends StatefulWidget {
  final String maqomId;
  final Color lineColor;
  final bool includeFajrOnly;
  final String? activePhraseId;
  final double? activePhrasePositionSec;

  const MaqomFullContourView({
    super.key,
    required this.maqomId,
    this.lineColor = const Color(0xFFDC2626),
    this.includeFajrOnly = false,
    this.activePhraseId,
    this.activePhrasePositionSec,
  });

  @override
  State<MaqomFullContourView> createState() => _MaqomFullContourViewState();
}

class _MaqomFullContourViewState extends State<MaqomFullContourView> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _phraseKeys = {};

  @override
  void didUpdateWidget(covariant MaqomFullContourView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePhraseId != null &&
        widget.activePhraseId != oldWidget.activePhraseId) {
      // v1.26: faol jumla o'zgarganda, uni ko'rinadigan qismga
      // avtomatik skroll qilamiz (ijro davom etganda foydalanuvchi
      // qo'lda skroll qilishga majbur bo'lmasin).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _phraseKeys[widget.activePhraseId];
        final ctx = key?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.3,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MaqomData>(
      future: MaqomContourRepository.load(widget.maqomId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
        }
        final phrases =
            snap.data!.phrases.where((p) => widget.includeFajrOnly || !p.fajrOnly).toList();
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final p in phrases) ...[
                SizedBox(
                  key: _phraseKeys.putIfAbsent(p.id, () => GlobalKey()),
                  width: math.max(140, p.durationSec * 9),
                  child: MaqomPhraseChart(
                    phrase: p,
                    lineColor: widget.lineColor,
                    cursorTimeSec: p.id == widget.activePhraseId
                        ? widget.activePhrasePositionSec
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        );
      },
    );
  }
}
