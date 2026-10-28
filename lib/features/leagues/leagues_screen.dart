import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/dates.dart';
import '../../domain/league.dart';
import '../../state/controller.dart';

/// One medal emoji per tier, in the same order as [leagueTiers].
const _tierMedals = ['🥉', '🥈', '🥇', '🔷', '🔴', '💚', '🔮', '🦪', '⚫', '💎'];

/// Ranks 1..[_promotionCutoff] move up a tier.
const _promotionCutoff = 10;

/// Ranks after [_demotionCutoff] move down a tier.
const _demotionCutoff = 25;

const _weekLength = Duration(days: 7);

class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final now = ref.watch(clockProvider)();
    final tier = s.leagueTier.clamp(0, leagueTiers.length - 1).toInt();
    final monday = _mondayOf(now);
    final board = buildLeague(
      weekKey: weekKey(now),
      tier: tier,
      yourXp: s.weekXp(now),
      yourName: s.name,
      weekFraction: (now.difference(monday).inMilliseconds /
              _weekLength.inMilliseconds)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
    final timeLeft = DateTime(monday.year, monday.month, monday.day + 7)
        .difference(now);
    final lastResult = _parseResult(s.lastLeagueResult);

    final rows = <Widget>[];
    for (var i = 0; i < board.length; i++) {
      if (i == _promotionCutoff) {
        rows.add(_ZoneDivider(
          text: 'Ranks 1 to $_promotionCutoff move up',
          color: Palette.olive,
        ));
      }
      if (i == _demotionCutoff) {
        rows.add(_ZoneDivider(
          text: 'Ranks ${_demotionCutoff + 1} to ${board.length} move down',
          color: Palette.tomato,
        ));
      }
      rows.add(_RankRow(rank: i + 1, entry: board[i]));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('League')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _TierHeader(
            tierName: leagueTiers[tier],
            medal: _tierMedals[tier],
            timeLeftText: _timeLeftText(timeLeft),
          ),
          if (lastResult != null) ...[
            const SizedBox(height: 12),
            _ResultBanner(outcome: lastResult.outcome, rank: lastResult.rank),
          ],
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }
}

DateTime _mondayOf(DateTime now) =>
    DateTime(now.year, now.month, now.day - (now.weekday - 1));

String _timeLeftText(Duration left) {
  final days = left.inDays;
  final hours = left.inHours % 24;
  if (days > 0) return '${days}d ${hours}h left this week';
  if (left.inHours > 0) return '${left.inHours}h left this week';
  return '${left.inMinutes}m left this week';
}

/// Ordinal suffix helper: 1st, 2nd, 3rd, 4th, 11th, 12th, 13th, 21st, ...
String _ordinal(int n) {
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

/// Turns the stored "outcome:rank" string into parts. Null when unknown.
({String outcome, int rank})? _parseResult(String? raw) {
  if (raw == null) return null;
  final parts = raw.split(':');
  if (parts.length != 2) return null;
  final rank = int.tryParse(parts[1]);
  if (rank == null) return null;
  if (!const {'promoted', 'stayed', 'demoted'}.contains(parts[0])) return null;
  return (outcome: parts[0], rank: rank);
}

String _initial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({
    required this.tierName,
    required this.medal,
    required this.timeLeftText,
  });

  final String tierName;
  final String medal;
  final String timeLeftText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Current league: $tierName. $timeLeftText.',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(medal, style: const TextStyle(fontSize: 56)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tierName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Top 10 move up, bottom 5 move down',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeLeftText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.outcome, required this.rank});

  final String outcome;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final (text, color, icon) = switch (outcome) {
      'promoted' => (
          'Last week: promoted! You finished ${_ordinal(rank)}',
          Palette.olive,
          Icons.arrow_upward_rounded,
        ),
      'demoted' => (
          'Last week: demoted. You finished ${_ordinal(rank)}',
          Palette.tomato,
          Icons.arrow_downward_rounded,
        ),
      _ => (
          'Last week: stayed. You finished ${_ordinal(rank)}',
          Palette.sky,
          Icons.remove_rounded,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneDivider extends StatelessWidget {
  const _ZoneDivider({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: color, thickness: 2)),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.entry});

  final int rank;
  final LeagueEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final zoneColor = rank <= _promotionCutoff
        ? Palette.olive
        : rank > _demotionCutoff
            ? Palette.tomato
            : null;
    final background = entry.isYou
        ? Palette.lemon.withValues(alpha: 0.35)
        : (zoneColor?.withValues(alpha: 0.12) ?? Colors.transparent);
    final youSuffix = entry.isYou ? ', this is you' : '';

    return Semantics(
      label: '${_ordinal(rank)} place, ${entry.name}, ${entry.xp} XP$youSuffix',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: entry.isYou ? Border.all(color: Palette.lemonDark, width: 2) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$rank',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: entry.isYou
                    ? Palette.teal
                    : scheme.onSurface.withValues(alpha: 0.12),
                child: Text(
                  _initial(entry.name),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: entry.isYou ? Colors.white : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.isYou ? '${entry.name} (you)' : entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: entry.isYou ? FontWeight.w900 : FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${entry.xp} XP',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
