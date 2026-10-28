import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the fox as transparent PNGs for the Android home-screen widgets.
/// Run with: flutter test tool/render_widget_art_test.dart
const _moods = ['happy', 'proud', 'celebrating', 'sleeping', 'encouraging'];

void main() {
  testWidgets('render widget art', (t) async {
    await t.runAsync(() async {
      for (final mood in _moods) {
        final svg = File('assets/mascot/$mood.svg').readAsStringSync();
        final info = await vg.loadPicture(SvgStringLoader(svg), null);
        final rec = ui.PictureRecorder();
        final c = Canvas(rec, const Rect.fromLTWH(0, 0, 256, 256));
        c.scale(256 / info.size.width);
        c.drawPicture(info.picture);
        final img = await rec.endRecording().toImage(256, 256);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('android/app/src/main/res/drawable-nodpi/pip_$mood.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data!.buffer.asUint8List());
      }
    });
  });
}
