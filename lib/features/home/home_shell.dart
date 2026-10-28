import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/symbols.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/dates.dart';
import '../../state/app_state.dart';
import '../../state/cloud_sync.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';
import '../../state/reminder_service.dart';
import '../../state/widget_sync.dart';
import '../courses/course_picker.dart';
import '../leagues/leagues_screen.dart';
import '../path/path_screen.dart';
import '../practice/practice_screen.dart';
import '../profile/profile_screen.dart';
import '../quests/quests_screen.dart';
import '../shop/shop_screen.dart';

/// Bottom-tab shell with a live status bar (streak, gems, hearts, goal).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  Timer? _tick;

  static const _titles = ['Learn', 'Practice', 'League', 'Quests', 'Profile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh the home-screen widgets with today's numbers on every launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(widgetSyncProvider).schedule();
        // Rebuilds the next two weeks of reminders each time the app opens.
        ref.read(reminderServiceProvider).schedule();
      }
    });
    // Re-render once a minute so heart timers and day changes stay fresh.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) ref.read(appProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(appProvider.notifier).refresh();
      ref.read(reminderServiceProvider).schedule();
      ref.read(cloudSyncProvider.notifier).syncSoon();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider);
    final now = ref.watch(clockProvider)();
    final streak = s.streakAt(now);
    final hearts = s.heartsAt(now);
    final goal = (s.xpOn(dayKey(now)) / s.dailyGoalXp).clamp(0.0, 1.0);
    final pages = const [
      PathScreen(),
      PracticeScreen(),
      LeaguesScreen(),
      QuestsScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      appBar: _tab == 0 || _tab == 1
          ? AppBar(
              centerTitle: false,
              title: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Choose language, now ${ref.watch(courseProvider).language.name}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => showCoursePicker(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          ref.watch(courseProvider).language.flag,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ),
                  StatChip(
                    glyph: s.activeToday(now) ? Glyph.streak : Glyph.streakOff,
                    value: '$streak',
                    color: s.activeToday(now) ? Palette.tomato : Colors.grey,
                    semanticLabel: '$streak day streak',
                  ),
                  StatChip(
                    glyph: Glyph.gem,
                    value: '${s.gems}',
                    color: Palette.gem,
                    semanticLabel: '${s.gems} gems',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
                    ),
                  ),
                  StatChip(
                    glyph: Glyph.heart,
                    value: hearts >= maxHearts ? '$maxHearts' : '$hearts',
                    color: Palette.tomato,
                    semanticLabel: '$hearts hearts',
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 64,
                    child: Tooltip(
                      message: 'Daily goal',
                      child: ProgressBar(value: goal, color: Palette.lemon, height: 10),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (final (i, t) in _titles.indexed)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_icons[i], color: Theme.of(context).colorScheme.primary),
              label: t,
            ),
        ],
      ),
    );
  }

  static const _icons = [
    Icons.home_rounded,
    Icons.fitness_center_rounded,
    Icons.emoji_events_rounded,
    Icons.flag_rounded,
    Icons.person_rounded,
  ];
}
