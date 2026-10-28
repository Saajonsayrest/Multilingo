import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders every SVG in a folder to one contact sheet PNG.
/// Run with: SVG_DIR=assets/mascot SVG_OUT=/tmp/sheet.png flutter test tool/render_svgs_test.dart
void main() {
  testWidgets('render svg contact sheet', (t) async {
    await t.runAsync(() async {
      final dir = Directory(Platform.environment['SVG_DIR'] ?? 'assets/mascot');
      final out = Platform.environment['SVG_OUT'] ?? '/tmp/svg_sheet.png';
      final cell = double.parse(Platform.environment['SVG_CELL'] ?? '300');
      final cols = int.parse(Platform.environment['SVG_COLS'] ?? '6');
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.svg')).toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      final rows = (files.length / cols).ceil();
      final w = cols * cell;
      final h = rows * cell;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec, Rect.fromLTWH(0, 0, w, h));
      c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFF9F0));
      for (var i = 0; i < files.length; i++) {
        final info = await vg.loadPicture(SvgStringLoader(files[i].readAsStringSync()), null);
        final x = (i % cols) * cell;
        final y = (i ~/ cols) * cell;
        c.save();
        c.translate(x + 8, y + 8);
        final s = (cell - 16) / info.size.width;
        c.scale(s);
        c.drawPicture(info.picture);
        c.restore();
      }
      final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
