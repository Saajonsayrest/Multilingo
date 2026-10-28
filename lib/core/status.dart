import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// States shown with a rounded-square badge. Each kind has its own icon
/// shape as well as its own colour, so meaning never depends on colour alone.
enum StatusKind {
  success,
  error,
  failed,
  warning,
  info,
  loading,
  locked,
  offline,
  premium,
}

class _StatusStyle {
  const _StatusStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

_StatusStyle _styleOf(StatusKind kind) => switch (kind) {
      StatusKind.success => const _StatusStyle(Icons.check_rounded, Color(0xFF25A86A)),
      StatusKind.error => const _StatusStyle(Icons.close_rounded, Color(0xFFE85D63)),
      StatusKind.failed => const _StatusStyle(Icons.priority_high_rounded, Color(0xFF8E99A4)),
      StatusKind.warning => const _StatusStyle(Icons.warning_amber_rounded, Color(0xFFF2B84B)),
      StatusKind.info => const _StatusStyle(Icons.info_outline_rounded, Color(0xFF4B8DE8)),
      StatusKind.loading => const _StatusStyle(Icons.hourglass_top_rounded, Color(0xFF8875D8)),
      StatusKind.locked => const _StatusStyle(Icons.lock_rounded, Color(0xFF8E99A4)),
      StatusKind.offline => const _StatusStyle(Icons.wifi_off_rounded, Color(0xFF8E99A4)),
      StatusKind.premium => const _StatusStyle(Icons.workspace_premium_rounded, Color(0xFF8875D8)),
    };

Color statusColor(StatusKind kind) => _styleOf(kind).color;

/// The vector symbol (assets/status/) that shows each kind.
String _assetOf(StatusKind kind) => switch (kind) {
      StatusKind.success => 'correct_answer',
      StatusKind.error => 'incorrect_answer',
      StatusKind.failed => 'lesson_failed',
      StatusKind.warning => 'something_went_wrong',
      StatusKind.info => 'info',
      StatusKind.loading => 'loading',
      StatusKind.locked => 'permission_needed',
      StatusKind.offline => 'offline',
      StatusKind.premium => 'achievement_unlocked',
    };

/// A status symbol. Each kind has its own shape as well as its own colour.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.kind, {super.key, this.size = 40});

  final StatusKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: kind.name,
      child: ExcludeSemantics(
        child: SvgPicture.asset(
          'assets/status/${_assetOf(kind)}.svg',
          width: size,
          height: size,
        ),
      ),
    );
  }
}
