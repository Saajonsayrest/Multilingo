import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/symbols.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../state/app_state.dart';
import '../../state/controller.dart';

const _gemDark = Color(0xFF5A45C9);

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appProvider);
    final now = ref.watch(clockProvider)();
    final ctrl = ref.read(appProvider.notifier);

    final hearts = s.heartsAt(now);
    final heartsFull = hearts >= maxHearts;
    final boosting = s.boostActive(now);
    final boostLeft = Duration(
      milliseconds: s.xpBoostUntil - now.millisecondsSinceEpoch,
    );

    void report(bool bought) => showToast(
          context,
          bought ? 'Purchased' : 'Not enough gems or already full',
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatChip(
              glyph: Glyph.gem,
              value: '${s.gems}',
              color: Palette.gem,
              semanticLabel: '${s.gems} gems',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ShopCard(
            leading: const GlyphIcon(Glyph.heart, size: 40),
            title: 'Refill hearts',
            description:
                'Fill your hearts to $maxHearts right now. Hearts also come back by themselves over time.',
            status: heartsFull
                ? 'Your hearts are full'
                : 'Hearts: $hearts of $maxHearts',
            price: heartRefillGems,
            onBuy: heartsFull || s.gems < heartRefillGems
                ? null
                : () => report(ctrl.refillHeartsWithGems()),
          ),
          const SizedBox(height: 12),
          _ShopCard(
            leading: const Text('🧊', style: TextStyle(fontSize: 32)),
            title: 'Streak freeze',
            description:
                'Keeps your streak safe if you miss a day. You can own up to 2.',
            status: 'You own ${s.freezes} of 2',
            price: streakFreezeGems,
            onBuy: s.gems < streakFreezeGems || s.freezes >= 2
                ? null
                : () => report(ctrl.buyStreakFreeze()),
          ),
          const SizedBox(height: 12),
          _ShopCard(
            leading: const GlyphIcon(Glyph.xp, size: 40),
            title: 'XP boost',
            description:
                'Earn double XP for ${xpBoostDuration.inMinutes} minutes. Buying again adds more time.',
            status: boosting
                ? 'Active: ${_formatLeft(boostLeft)} left'
                : 'Not active',
            price: xpBoostGems,
            onBuy: s.gems < xpBoostGems
                ? null
                : () => report(ctrl.buyXpBoost()),
          ),
        ],
      ),
    );
  }
}

String _formatLeft(Duration d) {
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$seconds';
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.leading,
    required this.title,
    required this.description,
    required this.status,
    required this.price,
    required this.onBuy,
  });

  final Widget leading;
  final String title;
  final String description;
  final String status;
  final int price;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(child: leading),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              status,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Palette.teal,
              ),
            ),
            const SizedBox(height: 14),
            BigButton(
              label: 'Buy for $price',
              glyph: Glyph.gem,
              color: Palette.gem,
              shadow: _gemDark,
              onPressed: onBuy,
            ),
          ],
        ),
      ),
    );
  }
}
