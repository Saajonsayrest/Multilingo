import 'package:flutter/material.dart';

import 'status.dart';
import 'symbols.dart';
import 'theme.dart';

/// Chunky button with a "pressed down" depth edge.
class BigButton extends StatefulWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Palette.teal,
    this.shadow = Palette.tealDark,
    this.foreground = Colors.white,
    this.icon,
    this.glyph,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadow;
  final Color foreground;
  final IconData? icon;

  /// A colour symbol shown after the label, for example a gem price.
  final Glyph? glyph;
  final bool expanded;

  /// Quiet outlined variant for secondary actions.
  factory BigButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool expanded = true,
  }) =>
      BigButton(
        key: key,
        label: label,
        onPressed: onPressed,
        color: Colors.white,
        shadow: Palette.mist,
        foreground: Palette.teal,
        icon: icon,
        expanded: expanded,
      );

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : Palette.mist;
    final shadow = enabled ? widget.shadow : const Color(0xFFCFC8B8);
    final fg = enabled ? widget.foreground : const Color(0xFF9A9384);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: widget.expanded ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          margin: EdgeInsets.only(top: _down ? 4 : 0, bottom: _down ? 0 : 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: shadow, offset: Offset(0, _down ? 0 : 4)),
            ],
          ),
          child: Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  fontSize: 15,
                ),
              ),
              if (widget.glyph != null) ...[
                const SizedBox(width: 8),
                GlyphIcon(widget.glyph!, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill with a symbol and a number, used in app bars.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.glyph,
    required this.value,
    this.color = Palette.ink,
    this.onTap,
    this.semanticLabel,
  });

  final Glyph glyph;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? value,
      button: onTap != null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlyphIcon(glyph, size: 24),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = Palette.olive,
    this.height = 14,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: Palette.mist),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}

/// Section title used on list screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      );
}

/// A short message. With [kind], a status badge sits next to the text.
void showToast(BuildContext context, String message, {StatusKind? kind}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: kind == null
            ? Text(message)
            : Row(
                children: [
                  StatusBadge(kind, size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
      ),
    );
}
