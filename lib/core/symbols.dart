import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Small vector symbols that replace emoji, so every device shows the same art.
enum Glyph {
  streak('status/streak_continued'),
  streakOff('status/streak_continued'),
  gem('brand/gem'),
  heart('brand/life_heart'),
  xp('status/xp'),
  goal('status/goal_achieved'),
  star('status/perfect_score'),
  trophy('status/lesson_completed'),
  correct('status/correct_answer'),
  incorrect('status/incorrect_answer'),
  badge('status/achievement_unlocked'),
  medal('status/medal'),
  milestone('status/milestone'),
  book('brand/book');

  const Glyph(this.asset);

  final String asset;
}

class GlyphIcon extends StatelessWidget {
  const GlyphIcon(this.glyph, {super.key, this.size = 22});

  final Glyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.asset(
        'assets/${glyph.asset}.svg',
        width: size,
        height: size,
        // An unlit streak is a flat grey flame.
        colorFilter: glyph == Glyph.streakOff
            ? const ColorFilter.mode(Color(0xFFC3CAC6), BlendMode.srcIn)
            : null,
      ),
    );
  }
}

/// A glyph that sits inside a line of text, for example "+5" then a gem.
InlineSpan glyphSpan(Glyph glyph, {double size = 18}) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GlyphIcon(glyph, size: size),
      ),
    );
