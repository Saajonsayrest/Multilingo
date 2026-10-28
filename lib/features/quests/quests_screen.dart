import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/symbols.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/dates.dart';
import '../../domain/quests.dart';
import '../../state/controller.dart';

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final now = ref.watch(clockProvider)();
    final today = dayKey(now);

    // Quest progress and claims belong to [AppState.questDay]. If the day has
    // rolled over and the app has not refreshed yet, show nothing stale.
    final sameDay = s.questDay == today;
    final progress = sameDay ? s.questProgress : const <String, int>{};
    final claimed = sameDay ? s.questClaimed : const <String>{};
    final quests = questsForDay(today);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quests'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Daily'), Tab(text: 'Badges')],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _DailyGoalCard(xp: s.xpOn(today), goal: s.dailyGoalXp),
                const SectionTitle("Today's quests"),
                for (final q in quests)
                  _QuestCard(
                    quest: q,
                    progress: progress[q.id] ?? 0,
                    claimed: claimed.contains(q.id),
                  ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SectionTitle('Achievements'),
                for (final a in achievementDefs)
                  _BadgeCard(
                    def: a,
                    unlocked: s.achievements.contains(a.id),
                    claimed: s.achievementsClaimed.contains(a.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.xp, required this.goal});

  final int xp;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = xp >= goal;
    final fraction =
        goal <= 0 ? 1.0 : (xp / goal).clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Daily goal',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '$xp / $goal XP',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Daily goal progress: $xp of $goal XP today',
              child: ProgressBar(
                value: fraction,
                color: reached ? Palette.olive : Palette.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reached
                  ? 'Goal reached. Great work!'
                  : '${goal - xp} XP to go today',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  const _QuestCard({
    required this.quest,
    required this.progress,
    required this.claimed,
  });

  final QuestDef quest;
  final int progress;
  final bool claimed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shown = progress.clamp(0, quest.target).toInt();
    final fraction = (progress / quest.target).clamp(0.0, 1.0).toDouble();
    final canClaim = !claimed && progress >= quest.target;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: '${quest.title}. $shown of ${quest.target}. '
                    'Reward ${quest.gems} gems.',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              quest.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const GlyphIcon(Glyph.gem, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${quest.gems}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ProgressBar(value: fraction, color: Palette.olive),
                      const SizedBox(height: 6),
                      Text(
                        '$shown / ${quest.target}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: claimed ? 'Claimed' : 'Claim',
                color: Palette.olive,
                shadow: Palette.oliveDark,
                onPressed: canClaim
                    ? () {
                        final ok = ref
                            .read(appProvider.notifier)
                            .claimQuest(quest.id);
                        if (ok) showToast(context, '+${quest.gems} gems');
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends ConsumerWidget {
  const _BadgeCard({
    required this.def,
    required this.unlocked,
    required this.claimed,
  });

  final AchievementDef def;
  final bool unlocked;
  final bool claimed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = !unlocked
        ? 'Locked'
        : claimed
            ? 'Unlocked, reward claimed'
            : 'Unlocked, reward ready';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: '${def.title}. ${def.description}. $status.',
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Opacity(
                        opacity: unlocked ? 1 : 0.3,
                        child: Text(def.emoji,
                            style: const TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              def.description,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (unlocked) ...[
                const SizedBox(height: 12),
                BigButton(
                  label: claimed ? 'Claimed' : 'Claim ${def.gems}',
                  glyph: claimed ? null : Glyph.gem,
                  color: Palette.gem,
                  shadow: const Color(0xFF5A46C7),
                  onPressed: claimed
                      ? null
                      : () => ref
                          .read(appProvider.notifier)
                          .claimAchievement(def.id),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
