import 'package:flutter/material.dart';

/// Descreve um botão de ação dentro de uma secção.
class ActionItem {
  const ActionItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;

  /// `null` desabilita o botão.
  final VoidCallback? onPressed;
  final bool destructive;
}

/// Secção agrupando ações relacionadas dentro de um cartão.
class ActionSection extends StatelessWidget {
  const ActionSection({
    super.key,
    required this.title,
    required this.icon,
    required this.actions,
  });

  final String title;
  final IconData icon;
  final List<ActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions)
                  _ActionButton(action: action),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final ActionItem action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (action.destructive) {
      return OutlinedButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.error,
          side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
        ),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
    );
  }
}
