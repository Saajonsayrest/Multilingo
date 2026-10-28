// Generates the fox mascot SVGs into assets/mascot/.
// Run with: dart run tool/gen_mascot.dart
// Only SVG features flutter_svg supports are used (paths, gradients, clipPath).
import 'dart:io';
import 'dart:math';

const ink = '#1F1B1E';
const dark = '#5A2E22';

const _head = 'M100 44C138 44 160 62 166 86L178 96L164 104L176 117'
    'C160 133 130 141 100 141C70 141 40 133 24 117L36 104L22 96L34 86'
    'C40 62 62 44 100 44Z';

String _defs() => '''<defs>
<radialGradient id="fur" cx="50%" cy="30%" r="75%"><stop offset="0" stop-color="#FFA660"/><stop offset=".55" stop-color="#F58A3E"/><stop offset="1" stop-color="#E06C2A"/></radialGradient>
<linearGradient id="furD" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#EE7A33"/><stop offset="1" stop-color="#C45820"/></linearGradient>
<radialGradient id="cream" cx="50%" cy="40%" r="70%"><stop offset="0" stop-color="#FFFAEF"/><stop offset="1" stop-color="#FBE3C2"/></radialGradient>
<linearGradient id="scarf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3BB27A"/><stop offset="1" stop-color="#1C8056"/></linearGradient>
<clipPath id="headClip"><path d="$_head"/></clipPath>
</defs>''';

// ---- small shapes ----------------------------------------------------------

String _star(double cx, double cy, double r, String fill) {
  final pts = <String>[];
  for (var i = 0; i < 10; i++) {
    final a = -pi / 2 + i * pi / 5;
    final rr = i.isEven ? r : r * 0.45;
    pts.add('${(cx + rr * cos(a)).toStringAsFixed(1)},${(cy + rr * sin(a)).toStringAsFixed(1)}');
  }
  return '<polygon points="${pts.join(' ')}" fill="$fill" stroke="$fill" stroke-width="2" stroke-linejoin="round"/>';
}

String _sparkle(double x, double y, double s, String fill) =>
    '<path d="M$x ${y - s}Q$x $y ${x + s} $y' 'Q$x $y $x ${y + s}Q$x $y ${x - s} $y' 'Q$x $y $x ${y - s}Z" fill="$fill"/>';

String _heart(double x, double y, double s, String fill) =>
    '<path d="M$x ${y + s * .9}C${x - s * 1.6} ${y - s * .1} ${x - s * .6} ${y - s * 1.1} $x ${y - s * .35}'
    'C${x + s * .6} ${y - s * 1.1} ${x + s * 1.6} ${y - s * .1} $x ${y + s * .9}Z" fill="$fill"/>';

String _question(double x, double y, String color) =>
    '<g transform="translate($x $y)"><path d="M0 8C0 -2 14 -2 14 7C14 14 6 14 6 21" fill="none" stroke="$color" stroke-width="4.5" stroke-linecap="round"/>'
    '<circle cx="6" cy="29" r="2.8" fill="$color"/></g>';

String _bang(double x, double y, String color) =>
    '<g transform="translate($x $y)"><path d="M0 0L0 15" stroke="$color" stroke-width="5.5" stroke-linecap="round"/><circle cx="0" cy="24" r="3.2" fill="$color"/></g>';

String _note(double x, double y, String color) =>
    '<g transform="translate($x $y)"><ellipse cx="0" cy="14" rx="6" ry="4.6" fill="$color"/><path d="M5.2 14L5.2 -4Q11 0 13 6" fill="none" stroke="$color" stroke-width="2.6" stroke-linecap="round"/></g>';

String _confetti(List<(double, double, double, String)> items) => items
    .map((e) =>
        '<rect x="${e.$1}" y="${e.$2}" width="7" height="3.6" rx="1.2" fill="${e.$4}" transform="rotate(${e.$3} ${e.$1 + 3} ${e.$2 + 2})"/>')
    .join();

String _zzz() => '<g fill="none" stroke="#2E9D68" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M150 56h14l-14 16h14"/><path d="M172 30h10l-10 12h10" stroke-width="2.8"/></g>';

String _retry() =>
    '<g fill="none" stroke="#2E9D68" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M186 34A18 18 0 1 0 176 54"/><path d="M188 18L186 34L170 31"/></g>';

String _bubble() => '<g><path d="M146 38L152 54L166 40Z" fill="#5C6BE0"/>'
    '<rect x="146" y="6" width="50" height="38" rx="19" fill="#5C6BE0"/>'
    '<circle cx="160" cy="25" r="3.8" fill="#fff"/><circle cx="171" cy="25" r="3.8" fill="#fff"/><circle cx="182" cy="25" r="3.8" fill="#fff"/></g>';

String _thought() => '<circle cx="152" cy="52" r="4" fill="#C9D6D0"/><circle cx="162" cy="40" r="6" fill="#C9D6D0"/>'
    '<circle cx="178" cy="24" r="10" fill="#C9D6D0"/>';

String _drop(double x, double y) =>
    '<path d="M$x $y' 'C${x + 7} ${y + 9} ${x + 7} ${y + 17} $x ${y + 17}C${x - 7} ${y + 17} ${x - 7} ${y + 9} $x ${y}Z" fill="#7FB9F2"/>';

// ---- parts -----------------------------------------------------------------

String _tail() => '<path d="M74 180C24 194 4 144 12 106C16 88 34 84 46 96C38 118 52 142 84 152Z" fill="url(#fur)"/>'
    '<path d="M12 106C16 88 34 84 46 96C34 96 26 102 24 118C16 116 12 112 12 106Z" fill="#FFF6E8"/>'
    '<path d="M20 150C30 160 46 166 64 166" fill="none" stroke="#D9642A" stroke-width="2.4" stroke-linecap="round" opacity=".5"/>';

String _pack() => '<rect x="48" y="112" width="104" height="66" rx="22" fill="#1F7A52"/>';

String _body() => '<ellipse cx="80" cy="190" rx="16" ry="9" fill="#6B3B2A"/><ellipse cx="120" cy="190" rx="16" ry="9" fill="#6B3B2A"/>'
    '<ellipse cx="100" cy="154" rx="45" ry="40" fill="url(#fur)"/>'
    '<ellipse cx="100" cy="162" rx="25" ry="29" fill="url(#cream)"/>'
    '<path d="M62 130Q66 156 72 178" fill="none" stroke="#1F7A52" stroke-width="9" stroke-linecap="round"/>'
    '<path d="M138 130Q134 156 128 178" fill="none" stroke="#1F7A52" stroke-width="9" stroke-linecap="round"/>'
    '<rect x="64" y="154" width="9" height="6" rx="2" fill="#F6B93B"/><rect x="127" y="154" width="9" height="6" rx="2" fill="#F6B93B"/>';

String _arm(double sx, double sy, double theta, [double len = 36]) =>
    '<g transform="translate($sx $sy) rotate($theta) scale(1 ${len / 36})">'
    '<path d="M-8 0C-11 14-11 28-5 36C1 41 10 37 9 28C9 16 8 8 8 0Z" fill="url(#fur)"/>'
    '<ellipse cx="0" cy="33" rx="8.6" ry="7" fill="url(#furD)"/></g>';

String _scarf() => '<path d="M56 126C80 142 120 142 144 126L100 172Z" fill="url(#scarf)"/>'
    '<path d="M62 130C84 144 116 144 138 130" fill="none" stroke="#1C8056" stroke-width="5" stroke-linecap="round"/>'
    '<path d="M84 150L100 164L116 150" fill="none" stroke="#8EDDB5" stroke-width="2" stroke-dasharray="3 3" stroke-linecap="round" opacity=".8"/>';

String _ear(bool left) {
  final t = left ? '' : ' transform="translate(200 0) scale(-1 1)"';
  return '<g$t><path d="M40 84C28 52 32 26 46 10C68 14 90 32 96 60Z" fill="$dark" stroke="$dark" stroke-width="2" stroke-linejoin="round"/>'
      '<path d="M45 84C36 58 40 36 52 24C68 30 84 44 91 62Z" fill="url(#fur)"/>'
      '<path d="M53 76C47 58 48 46 54 38C65 43 75 53 79 64Z" fill="url(#cream)"/></g>';
}

String _headShape() => '<path d="$_head" fill="url(#fur)" stroke="#F58A3E" stroke-width="3" stroke-linejoin="round"/>'
    '<g clip-path="url(#headClip)"><path d="M16 104C34 94 62 98 82 108C92 113 96 114 100 114C104 114 108 113 118 108C138 98 166 94 184 104L184 150L16 150Z" fill="url(#cream)"/></g>'
    '<path d="M36 104L24 117C40 133 70 141 100 141C130 141 160 133 176 117L164 104" fill="none" stroke="#FBE9CE" stroke-width="3.4" stroke-linejoin="round" stroke-linecap="round"/>'
    '<path d="M90 46L100 34L110 46Z" fill="#F58A3E" stroke="#F58A3E" stroke-width="3" stroke-linejoin="round"/>'
    '<path d="M44 80C60 62 86 56 100 58C114 56 140 62 156 80" fill="none" stroke="#FFB070" stroke-width="3" stroke-linecap="round" opacity=".5"/>';

String _eye(double x, String kind) {
  switch (kind) {
    case 'wide':
      return '<ellipse cx="$x" cy="92" rx="10.5" ry="13" fill="$ink"/><circle cx="${x + 3.5}" cy="86" r="4" fill="#fff"/><circle cx="${x - 3.5}" cy="98" r="2" fill="#fff"/>';
    case 'happy':
      return '<path d="M${x - 11} 97Q$x 81 ${x + 11} 97" fill="none" stroke="$ink" stroke-width="4.6" stroke-linecap="round"/>';
    case 'closed':
      return '<path d="M${x - 11} 90Q$x 102 ${x + 11} 90" fill="none" stroke="$ink" stroke-width="4.6" stroke-linecap="round"/>';
    case 'lookUp':
      return '<ellipse cx="${x + 2}" cy="89" rx="9.5" ry="12" fill="$ink"/><circle cx="${x + 5}" cy="83" r="3.8" fill="#fff"/><circle cx="${x - 1}" cy="94" r="1.8" fill="#fff"/>';
    case 'lookDown':
      return '<ellipse cx="$x" cy="96" rx="9.5" ry="11" fill="$ink"/><circle cx="${x + 3}" cy="91" r="3.6" fill="#fff"/><circle cx="${x - 3}" cy="101" r="1.8" fill="#fff"/>';
    default:
      return '<ellipse cx="$x" cy="92" rx="10.5" ry="13" fill="$ink"/><circle cx="${x + 3.6}" cy="86" r="4.2" fill="#fff"/><circle cx="${x - 3.4}" cy="97.5" r="2.1" fill="#fff"/>';
  }
}

String _brow(double x, bool left, String kind) {
  final s = left ? 1 : -1;
  const c = '#B5541F';
  String line(String d) => '<path d="$d" fill="none" stroke="$c" stroke-width="3.6" stroke-linecap="round"/>';
  switch (kind) {
    case 'up':
      return line('M${x - 10} 72Q$x 64 ${x + 10} 72');
    case 'worried':
      return line('M${x - 10 * s} 66L${x + 10 * s} 74');
    case 'angled':
      return line('M${x - 10 * s} 74L${x + 10 * s} 66');
    case 'raised':
      return left ? line('M${x - 10} 70Q$x 62 ${x + 10} 68') : line('M${x - 10} 74L${x + 10} 74');
    default:
      return '';
  }
}

String _mouth(String kind) {
  switch (kind) {
    case 'grin':
      return '<path d="M89 113Q100 115 111 113Q109 130 100 130Q91 130 89 113Z" fill="#4A1F25"/><ellipse cx="100" cy="124" rx="6.5" ry="4.2" fill="#F36B7C"/>';
    case 'open':
      return '<ellipse cx="100" cy="121" rx="7" ry="9" fill="#4A1F25"/><ellipse cx="100" cy="126" rx="4.5" ry="3" fill="#F36B7C"/>';
    case 'small':
      return '<path d="M95 116Q100 120 105 116" fill="none" stroke="$ink" stroke-width="3" stroke-linecap="round"/>';
    case 'flat':
      return '<path d="M94 118L106 118" fill="none" stroke="$ink" stroke-width="3" stroke-linecap="round"/>';
    case 'frown':
      return '<path d="M92 122Q100 114 108 122" fill="none" stroke="$ink" stroke-width="3" stroke-linecap="round"/>';
    case 'wavy':
      return '<path d="M90 119q5 -5 10 0t10 0" fill="none" stroke="$ink" stroke-width="3" stroke-linecap="round"/>';
    default:
      return '<path d="M91 114Q100 123 109 114" fill="none" stroke="$ink" stroke-width="3.2" stroke-linecap="round"/>';
  }
}

String _nose() => '<path d="M93 105Q100 101 107 105Q105 112 100 113Q95 112 93 105Z" fill="$ink"/>'
    '<ellipse cx="97" cy="105" rx="2" ry="1" fill="#fff" opacity=".6"/>';

String _blush() => '<ellipse cx="56" cy="108" rx="9" ry="5" fill="#FF8F7A" opacity=".45"/><ellipse cx="144" cy="108" rx="9" ry="5" fill="#FF8F7A" opacity=".45"/>';

String _headphones() => '<path d="M33 96C30 44 170 44 167 96" fill="none" stroke="#1F5F5B" stroke-width="8" stroke-linecap="round"/>'
    '<rect x="20" y="82" width="22" height="38" rx="11" fill="#1F6F6B"/><rect x="158" y="82" width="22" height="38" rx="11" fill="#1F6F6B"/>'
    '<rect x="25" y="90" width="12" height="22" rx="6" fill="#2E8F86"/><rect x="163" y="90" width="12" height="22" rx="6" fill="#2E8F86"/>';

String _book() => '<path d="M50 150L98 158L98 198L50 190Z" fill="#2F7E87"/><path d="M150 150L102 158L102 198L150 190Z" fill="#276C75"/>'
    '<path d="M56 154L96 161L96 192L56 185Z" fill="#E9F4F3"/><path d="M144 154L104 161L104 192L144 185Z" fill="#DCEBEA"/>'
    '<path d="M98 158L98 198M102 158L102 198" stroke="#1D5961" stroke-width="2"/>'
    '<ellipse cx="54" cy="156" rx="8" ry="7" fill="url(#furD)"/><ellipse cx="146" cy="156" rx="8" ry="7" fill="url(#furD)"/>';

String _desk() => '<rect x="34" y="158" width="132" height="38" rx="8" fill="#fff" stroke="#8FC2C0" stroke-width="3"/>'
    '<rect x="46" y="150" width="26" height="34" rx="4" fill="#8B4A2B" transform="rotate(-8 59 167)"/>'
    '<path d="M112 168L150 176M112 178L146 185" stroke="#B8D4D2" stroke-width="2.5" stroke-linecap="round"/>'
    '<ellipse cx="72" cy="160" rx="8" ry="7" fill="url(#furD)"/><ellipse cx="128" cy="160" rx="8" ry="7" fill="url(#furD)"/>';

String _flag(double x, double y) => '<path d="M$x ${y + 2}L${x + 4} ${y - 48}" stroke="#8B5E3C" stroke-width="3" stroke-linecap="round"/>'
    '<path d="M${x + 4} ${y - 48}L${x + 30} ${y - 40}L${x + 4} ${y - 30}Z" fill="#4B8DE8"/>';

(double, double) _tip(double sx, double sy, double theta, double len) {
  final r = theta * pi / 180;
  return (sx - sin(r) * (len + 4), sy + cos(r) * (len + 4));
}

// ---- moods -------------------------------------------------------------------

class _Mood {
  const _Mood(
    this.name, {
    this.eyes = 'open',
    this.mouth = 'smile',
    this.brows = 'none',
    this.blush = true,
    this.armL = 14,
    this.armR = -14,
    this.lenL = 36,
    this.lenR = 36,
    this.tilt = 0,
    this.headgear = '',
    this.props = '',
    this.sleep = false,
    this.wink = false,
  });

  final String name, eyes, mouth, brows, headgear, props;
  final bool blush, sleep, wink;
  final double armL, armR, lenL, lenR, tilt;
}

String _gold(double x, double y, double r) => _star(x, y, r, '#F6B93B');

String _build(_Mood m) {
  final raisedL = m.armL > 90 || m.armL < -90;
  final raisedR = m.armR > 90 || m.armR < -90;
  final sb = StringBuffer();
  sb.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">');
  sb.write(_defs());
  sb.write(_tail());
  sb.write(_pack());
  sb.write(_body());
  if (m.sleep) {
    sb.write('<path d="M34 172C30 146 116 136 172 158C180 184 146 198 100 198C60 198 36 192 34 172Z" fill="url(#fur)"/>'
        '<path d="M34 172C30 156 44 146 62 144C50 154 48 166 50 180C40 180 35 177 34 172Z" fill="#FFF6E8"/>');
  } else {
    if (!raisedL) sb.write(_arm(66, 136, m.armL, m.lenL));
    if (!raisedR) sb.write(_arm(134, 136, m.armR, m.lenR));
    sb.write(_scarf());
  }
  if (m.sleep) sb.write(_scarf());
  final dy = m.sleep ? 26 : 0;
  sb.write('<g transform="translate(0 $dy) rotate(${m.tilt} 100 140)">');
  sb.write(_ear(true));
  sb.write(_ear(false));
  sb.write(_headShape());
  if (m.blush) sb.write(_blush());
  final eyeL = m.wink ? 'happy' : m.eyes;
  sb.write(_eye(74, m.eyes == 'happy' || m.eyes == 'closed' || m.eyes == 'wide' ? m.eyes : eyeL));
  sb.write(_eye(126, m.eyes));
  sb.write(_brow(74, true, m.brows));
  sb.write(_brow(126, false, m.brows));
  sb.write(_nose());
  sb.write(_mouth(m.mouth));
  sb.write(m.headgear);
  sb.write('</g>');
  if (raisedL) sb.write(_arm(66, 136, m.armL, m.lenL));
  if (raisedR) sb.write(_arm(134, 136, m.armR, m.lenR));
  sb.write(m.props);
  sb.write('</svg>');
  return sb.toString();
}

List<_Mood> _moods() {
  return [
    const _Mood('happy', mouth: 'grin'),
    _Mood('excited',
        eyes: 'wide', mouth: 'grin', brows: 'up', armL: 118, armR: -118, lenL: 44, lenR: 44,
        props: _gold(30, 28, 11) + _sparkle(176, 30, 7, '#F6B93B') + _sparkle(18, 56, 5, '#F6B93B')),
    _Mood('proud',
        eyes: 'happy', armL: 40, armR: -40,
        props: _sparkle(170, 36, 8, '#F6B93B') + _sparkle(30, 44, 5, '#2E9D68')),
    _Mood('encouraging', wink: true, mouth: 'grin', armR: -132, lenR: 40, props: _sparkle(176, 36, 7, '#F6B93B')),
    _Mood('thinking', eyes: 'lookUp', mouth: 'flat', brows: 'raised', armR: -165, lenR: 30, tilt: -4, props: _thought()),
    _Mood('curious', eyes: 'wide', mouth: 'small', brows: 'up', tilt: 8, props: _question(158, 18, '#2E9D68')),
    _Mood('confused',
        mouth: 'wavy', brows: 'worried', blush: false, tilt: -6,
        props: _question(22, 24, '#8875D8') + _drop(172, 58)),
    _Mood('surprised',
        eyes: 'wide', mouth: 'open', brows: 'up', blush: false, armL: 160, armR: -160, lenL: 28, lenR: 28,
        props: '${_bang(178, 26, '#F2B84B')}'
            '<path d="M36 40L44 48M164 40L156 48M24 70L34 72" stroke="#F2B84B" stroke-width="3.4" stroke-linecap="round"/>'),
    _Mood('celebrating',
        eyes: 'happy', mouth: 'grin', armL: 125, armR: -125, lenL: 44, lenR: 44,
        props: _heart(176, 46, 9, '#E85D63') + _gold(26, 30, 10) + _sparkle(180, 90, 6, '#8875D8') +
            _confetti([(48, 14, 20, '#4B8DE8'), (150, 12, -30, '#E85D63'), (14, 80, 40, '#2E9D68'), (184, 70, 10, '#F6B93B')])),
    _Mood('listening',
        eyes: 'closed', headgear: _headphones(), props: _note(166, 22, '#8875D8') + _note(26, 36, '#2E9D68')),
    _Mood('reading', eyes: 'lookDown', props: _book()),
    _Mood('speaking', mouth: 'open', armR: -130, lenR: 40, props: _bubble()),
    _Mood('concentrating', eyes: 'closed', mouth: 'flat', brows: 'angled', blush: false, props: _desk() + _question(160, 20, '#2E9D68')),
    const _Mood('sleeping', eyes: 'closed', mouth: 'small', sleep: true, tilt: -6, props: ''),
    _Mood('reassured',
        mouth: 'frown', brows: 'worried', tilt: -4, props: _heart(170, 40, 10, '#A8573A')),
    _Mood('tryAgain', wink: true, armR: -130, lenR: 40, props: _retry()),
    const _Mood('welcome', eyes: 'happy', mouth: 'grin', armL: 125, lenL: 44),
    _Mood('congratulating',
        eyes: 'wide', mouth: 'grin', brows: 'up', armL: 125, armR: -125, lenL: 44, lenR: 44,
        props: _gold(176, 34, 11) + _sparkle(24, 40, 7, '#F6B93B') +
            _confetti([(40, 12, 30, '#E85D63'), (150, 10, -20, '#4B8DE8'), (12, 90, -40, '#8875D8'), (182, 84, 30, '#2E9D68')])),
  ];
}

/// The app icon art: head and ears only, so it sits dead centre.
/// Its content spans x 22..178 and y 10..141, centre (100, 75.5).
String _iconArt() {
  final m = _moods().first;
  final sb = StringBuffer('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">');
  sb
    ..write(_defs())
    ..write(_ear(true))
    ..write(_ear(false))
    ..write(_headShape())
    ..write(_blush())
    ..write(_eye(74, m.eyes))
    ..write(_eye(126, m.eyes))
    ..write(_nose())
    ..write(_mouth(m.mouth))
    ..write('</svg>');
  return sb.toString();
}

void main() {
  Directory('assets/brand').createSync(recursive: true);
  File('assets/brand/app_icon.svg').writeAsStringSync(_iconArt());
  final out = Directory('assets/mascot')..createSync(recursive: true);
  for (final m in _moods()) {
    var svg = _build(m);
    if (m.name == 'sleeping') svg = svg.replaceFirst('</svg>', '${_zzz()}</svg>');
    if (m.name == 'welcome') {
      final t = _tip(66, 136, 125, 44);
      svg = svg.replaceFirst('</svg>', '${_flag(t.$1, t.$2)}${_sparkle(176, 40, 8, '#F6B93B')}</svg>');
    }
    File('${out.path}/${m.name}.svg').writeAsStringSync(svg);
  }
  stdout.writeln('wrote ${_moods().length} svgs');
}
