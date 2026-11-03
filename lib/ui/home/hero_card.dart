import 'package:flutter/material.dart';

const _curve = Curves.easeOutBack; // slight spring overshoot
const _dur = Duration(milliseconds: 600);

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.on,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.onToggle,
  });

  final bool on;
  final String label;
  final String title;
  final String subtitle;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = on ? cs.onPrimary : cs.onSurface;

    return AnimatedContainer(
      duration: _dur,
      curve: _curve,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: on ? cs.primary : cs.surfaceContainerHighest,
        borderRadius: on
            ? const BorderRadius.only(
                topLeft: Radius.circular(64),
                topRight: Radius.circular(28),
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(64),
              )
            : BorderRadius.circular(40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: _dur,
            curve: _curve,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: on ? cs.onPrimary : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(on ? 22 : 32),
            ),
            child: Icon(
              on ? Icons.shield_rounded : Icons.shield_outlined,
              color: on ? cs.primary : cs.onSurfaceVariant,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: tt.titleMedium?.copyWith(color: fg.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: tt.displaySmall?.copyWith(color: fg, fontSize: 40),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: tt.bodyLarge?.copyWith(color: fg.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ExpressiveToggle(value: on, onChanged: (_) => onToggle()),
          ),
        ],
      ),
    );
  }
}

class ExpressiveToggle extends StatelessWidget {
  const ExpressiveToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: _dur,
        curve: _curve,
        width: 96,
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: value ? cs.onPrimary : cs.outline.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(value ? 20 : 28),
        ),
        child: AnimatedAlign(
          duration: _dur,
          curve: _curve,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: _dur,
            curve: _curve,
            width: value ? 52 : 44,
            height: 44,
            decoration: BoxDecoration(
              color: value ? cs.primary : cs.surface,
              borderRadius: BorderRadius.circular(value ? 14 : 22),
            ),
            child: Icon(
              value ? Icons.check_rounded : Icons.power_settings_new_rounded,
              size: 22,
              color: value ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
