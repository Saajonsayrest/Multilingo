import 'dart:math';

/// Offline "league" simulation: 29 bots plus the learner.
/// Bot scores are a pure function of (week, tier, index, time), so the board
/// is stable between app launches and needs no server.
const leagueTiers = [
  'Bronze',
  'Silver',
  'Gold',
  'Sapphire',
  'Ruby',
  'Emerald',
  'Amethyst',
  'Pearl',
  'Obsidian',
  'Diamond',
];

const _botNames = [
  'Luca', 'Sofia', 'Marco', 'Giulia', 'Matteo', 'Chiara', 'Andrea', 'Elena',
  'Paolo', 'Martina', 'Davide', 'Sara', 'Stefano', 'Alice', 'Fabio', 'Ilaria',
  'Nicola', 'Beatrice', 'Simone', 'Valentina', 'Enrico', 'Federica', 'Gianni',
  'Rosa', 'Tommaso', 'Camilla', 'Dario', 'Greta', 'Pietro',
];

class LeagueEntry {
  const LeagueEntry(this.name, this.xp, {this.isYou = false});

  final String name;
  final int xp;
  final bool isYou;
}

/// [weekFraction] is 0..1 through the week.
List<LeagueEntry> buildLeague({
  required String weekKey,
  required int tier,
  required int yourXp,
  required String yourName,
  required double weekFraction,
}) {
  final seed = weekKey.hashCode ^ (tier * 7919);
  final rnd = Random(seed);
  // Higher tiers have more active bots.
  final scale = 180 + tier * 60;
  final bots = <LeagueEntry>[];
  for (var i = 0; i < _botNames.length; i++) {
    final base = (rnd.nextDouble() * rnd.nextDouble() * 2.2 + 0.1) * scale;
    final active = 0.55 + rnd.nextDouble() * 0.45;
    bots.add(LeagueEntry(
      _botNames[i],
      (base * (weekFraction * active).clamp(0.0, 1.0) * 2).round(),
    ));
  }
  final all = [...bots, LeagueEntry(yourName, yourXp, isYou: true)];
  all.sort((a, b) {
    final c = b.xp.compareTo(a.xp);
    if (c != 0) return c;
    // Ties favour the learner so a fresh board is not discouraging.
    if (a.isYou) return -1;
    if (b.isYou) return 1;
    return a.name.compareTo(b.name);
  });
  return all;
}

enum LeagueOutcome { promoted, stayed, demoted }

/// Top 10 move up, bottom 5 move down (never below Bronze / above Diamond).
LeagueOutcome outcomeForRank(int rank, int tier) {
  if (rank <= 10 && tier < leagueTiers.length - 1) return LeagueOutcome.promoted;
  if (rank > 25 && tier > 0) return LeagueOutcome.demoted;
  return LeagueOutcome.stayed;
}
