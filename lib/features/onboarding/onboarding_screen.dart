import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mascot.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../data/languages.dart';
import '../../state/cloud_sync.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';
import '../settings/account_screen.dart';

/// Three quick steps: name, level, daily goal.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  int _step = 0;
  String _level = 'beginner';
  int _goal = 20;

  static const _levels = [
    ('beginner', '🌱', 'I am new to this language'),
    ('some', '🌿', 'I know a few words'),
    ('travel', '🧳', 'I want to travel and chat'),
  ];
  static const _goals = [
    (10, 'Casual', '10 XP, about 3 minutes'),
    (20, 'Regular', '20 XP, about 6 minutes'),
    (30, 'Serious', '30 XP, about 10 minutes'),
    (50, 'Intense', '50 XP, about 15 minutes'),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    ref.read(appProvider.notifier).completeOnboarding(
          name: _name.text,
          dailyGoalXp: _goal,
          level: _level,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressBar(value: (_step + 1) / 3),
              const SizedBox(height: 28),
              Expanded(child: SingleChildScrollView(child: _content(context))),
              BigButton(
                label: _step == 2 ? "Let's go" : 'Continue',
                onPressed: _next,
              ),
              if (_step > 0)
                TextButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                )
              else if (ref.watch(cloudSyncProvider).phase != SyncPhase.unavailable)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
                  ),
                  child: Text(AppLocalizations.of(context).onboardingHaveAccount),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final title = Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(fontWeight: FontWeight.w900);
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Mascot(mood: MascotMood.welcome, size: 150)),
            const SizedBox(height: 12),
            Text('Ciao! I am Pip.', style: title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Welcome to Multilingo. Let us learn ${ref.watch(courseProvider).language.name} in small, fun steps. What should I call you?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (final lang in languages)
                  ChoiceChip(
                    avatar: Text(lang.flag),
                    label: Text(lang.name),
                    selected: ref.watch(activeCourseProvider) == lang.id,
                    onSelected: (_) =>
                        ref.read(appProvider.notifier).switchCourse(lang.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('How much ${ref.watch(courseProvider).language.name} do you know?', style: title),
            const SizedBox(height: 16),
            for (final (id, emoji, label) in _levels)
              _choice(
                selected: _level == id,
                onTap: () => setState(() => _level = id),
                leading: emoji,
                title: label,
              ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pick a daily goal', style: title),
            const SizedBox(height: 16),
            for (final (xp, name, desc) in _goals)
              _choice(
                selected: _goal == xp,
                onTap: () => setState(() => _goal = xp),
                leading: '⚡',
                title: name,
                subtitle: desc,
              ),
          ],
        );
    }
  }

  Widget _choice({
    required bool selected,
    required VoidCallback onTap,
    required String leading,
    required String title,
    String? subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: title,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: selected ? scheme.primary.withValues(alpha: 0.1) : null,
              border: Border.all(
                color: selected ? scheme.primary : Palette.mist,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(leading, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      if (subtitle != null) Text(subtitle),
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
