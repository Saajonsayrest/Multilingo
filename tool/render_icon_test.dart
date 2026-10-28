import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws the app icon and launch screen art from assets/brand/app_icon.svg.
/// Run with: flutter test tool/render_icon_test.dart
const _size = 1024.0;

/// The icon art is drawn in a 200 box and its content is centred on (100, 75.5).
/// [fill] is how much of the canvas width the 156 wide art takes.
void _fox(Canvas c, ui.Picture art, {required double canvas, required double fill}) {
  c.save();
  c.translate(canvas / 2, canvas / 2);
  c.scale(canvas * fill / 156);
  c.translate(-100, -75.5);
  c.drawPicture(art);
  c.restore();
}

Future<void> _write(String path, double size, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder, Rect.fromLTWH(0, 0, size, size)));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void _background(Canvas c) {
  c.drawRect(
    const Rect.fromLTWH(0, 0, _size, _size),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(_size, _size),
        const [Color(0xFF3DB57C), Color(0xFF176B4A)],
      ),
  );
}

void main() {
  testWidgets('render icons', (t) async {
    await t.runAsync(() async {
      final svg = File('assets/brand/app_icon.svg').readAsStringSync();
      final art = (await vg.loadPicture(SvgStringLoader(svg), null)).picture;
      // Full icon (iOS and old Android).
      await _write('assets/icon/icon.png', _size, (c) {
        _background(c);
        _fox(c, art, canvas: _size, fill: 0.68);
      });
      // Adaptive foreground: transparent, fox inside the 66% safe zone.
      await _write('assets/icon/icon_foreground.png', _size, (c) {
        _fox(c, art, canvas: _size, fill: 0.5);
      });
      // Launch screens: the fox centred on the green screen.
      await _write('android/app/src/main/res/drawable-nodpi/splash_fox.png', 480, (c) {
        _fox(c, art, canvas: 480, fill: 1);
      });
      for (final (name, px) in [('LaunchImage', 160.0), ('LaunchImage@2x', 320.0), ('LaunchImage@3x', 480.0)]) {
        await _write('ios/Runner/Assets.xcassets/LaunchImage.imageset/$name.png', px, (c) {
          _fox(c, art, canvas: px, fill: 1);
        });
      }
    });
  });
}
