import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quick preview of an axolotl mascot idea. Not used by the app yet.
const _pink = Color(0xFFFFB3C7);
const _pinkLight = Color(0xFFFFE0E8);
const _coral = Color(0xFFFF7A9C);
const _ink = Color(0xFF2B2A33);

void _axolotl(Canvas c, {required String mood}) {
  final fill = Paint()..color = _pink;
  // Tail.
  final tail = Path()
    ..moveTo(130, 168)
    ..cubicTo(180, 176, 196, 140, 176, 122)
    ..cubicTo(176, 146, 160, 158, 128, 154)
    ..close();
  c.drawPath(tail, Paint()..color = _coral);
  // Body.
  c.drawOval(Rect.fromCenter(center: const Offset(100, 152), width: 96, height: 80), fill);
  c.drawOval(Rect.fromCenter(center: const Offset(100, 160), width: 56, height: 52), Paint()..color = _pinkLight);
  // Feet.
  for (final x in [74.0, 126.0]) {
    c.drawOval(Rect.fromCenter(center: Offset(x, 193), width: 28, height: 12), Paint()..color = _coral);
  }
  // Arms.
  final armY = mood == 'excited' ? 128.0 : 150.0;
  for (final left in [true, false]) {
    c.save();
    c.translate(left ? 54 : 146, armY);
    c.rotate(mood == 'excited' ? (left ? 0.9 : -0.9) : (left ? 0.4 : -0.4));
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -7, 20, 30), const Radius.circular(10)),
      Paint()..color = _coral,
    );
    c.restore();
  }
  // Gills: three feathery stalks on each side.
  final stalk = Paint()
    ..color = _coral
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  for (final left in [true, false]) {
    final dir = left ? -1.0 : 1.0;
    final base = Offset(left ? 50 : 150, 92);
    final ends = [const Offset(26, 50), const Offset(10, 84), const Offset(24, 120)];
    for (final e in ends) {
      final tip = Offset(left ? e.dx : 200 - e.dx, e.dy);
      final path = Path()
        ..moveTo(base.dx, base.dy + (e.dy - 84) * 0.25)
        ..quadraticBezierTo(base.dx + dir * 14, e.dy - 6, tip.dx, tip.dy);
      c.drawPath(path, stalk);
      c.drawCircle(tip, 8, Paint()..color = _coral);
      c.drawCircle(tip + const Offset(-2, -2), 3, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
  }
  // Head.
  c.drawOval(Rect.fromCenter(center: const Offset(100, 94), width: 130, height: 104), fill);
  c.drawOval(
    Rect.fromCenter(center: const Offset(100, 66), width: 70, height: 22),
    Paint()..color = Colors.white.withValues(alpha: 0.35),
  );
  // Cheeks.
  final blush = Paint()..color = _coral.withValues(alpha: 0.45);
  c.drawOval(Rect.fromCenter(center: const Offset(60, 108), width: 22, height: 13), blush);
  c.drawOval(Rect.fromCenter(center: const Offset(140, 108), width: 22, height: 13), blush);
  // Eyes and mouth.
  final eyeStroke = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  for (final x in [76.0, 124.0]) {
    if (mood == 'sleeping') {
      c.drawArc(Rect.fromCenter(center: Offset(x, 90), width: 20, height: 14), 0.3, 2.5, false, eyeStroke);
    } else {
      final h = mood == 'excited' ? 22.0 : 18.0;
      c.drawOval(Rect.fromCenter(center: Offset(x, 92), width: h * 0.8, height: h), Paint()..color = _ink);
      c.drawCircle(Offset(x - 2.5, 87), 3, Paint()..color = Colors.white);
    }
  }
  final mouth = Path();
  if (mood == 'excited') {
    mouth
      ..moveTo(82, 112)
      ..quadraticBezierTo(100, 112, 118, 112)
      ..quadraticBezierTo(112, 134, 100, 134)
      ..quadraticBezierTo(88, 134, 82, 112)
      ..close();
    c.drawPath(mouth, Paint()..color = _ink);
    c.drawOval(Rect.fromCenter(center: const Offset(100, 129), width: 16, height: 8), Paint()..color = const Color(0xFFFF6B8B));
  } else {
    mouth
      ..moveTo(86, 112)
      ..quadraticBezierTo(100, 126, 114, 112);
    c.drawPath(mouth, eyeStroke);
  }
  if (mood == 'sleeping') {
    final z = Paint()
      ..color = const Color(0xFF4B8DE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final (o, r) in [(const Offset(168, 40), 9.0), (const Offset(184, 18), 6.0)]) {
      c.drawPath(
        Path()
          ..moveTo(o.dx - r, o.dy - r)
          ..lineTo(o.dx + r, o.dy - r)
          ..lineTo(o.dx - r, o.dy + r)
          ..lineTo(o.dx + r, o.dy + r),
        z,
      );
    }
  }
}

void main() {
  testWidgets('render axolotl preview', (t) async {
    await t.runAsync(() async {
      const cell = 300.0;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec, const Rect.fromLTWH(0, 0, cell * 3, cell));
      c.drawRect(const Rect.fromLTWH(0, 0, cell * 3, cell), Paint()..color = const Color(0xFFFFF9F0));
      var i = 0;
      for (final mood in ['happy', 'excited', 'sleeping']) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(i * cell + 14, 14, cell - 28, cell - 28),
            const Radius.circular(28),
          ),
          Paint()..color = Colors.white,
        );
        c.save();
        c.translate(i * cell + 30, 30);
        c.scale(240 / 200);
        _axolotl(c, mood: mood);
        c.restore();
        i++;
      }
      final img = await rec.endRecording().toImage((cell * 3).toInt(), cell.toInt());
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('/tmp/claude-shots/axolotl.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
