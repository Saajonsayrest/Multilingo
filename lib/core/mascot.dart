import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The fox mascot. Each mood is a vector file in assets/mascot/, made by
/// tool/gen_mascot.dart, so it stays sharp at every size.
enum MascotMood {
  happy,
  excited,
  proud,
  encouraging,
  thinking,
  curious,
  confused,
  surprised,
  celebrating,
  listening,
  reading,
  speaking,
  concentrating,
  sleeping,
  reassured,
  tryAgain,
  welcome,
  congratulating,
}

/// The mascot as a widget. [semanticLabel] lets screen readers describe the mood.
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    this.mood = MascotMood.happy,
    this.size = 120,
    this.semanticLabel,
  });

  final MascotMood mood;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel ?? 'Fox mascot, ${mood.name}',
      child: ExcludeSemantics(
        child: SvgPicture.asset(
          'assets/mascot/${mood.name}.svg',
          width: size,
          height: size,
        ),
      ),
    );
  }
}
