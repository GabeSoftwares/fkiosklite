import 'package:flutter/material.dart';

import '../models/audit_entry.dart';

/// Painel de auditoria: mostra cada ação executada, mais recente primeiro,
/// com estado de sucesso/erro e timestamp.
class AuditLogPanel extends StatelessWidget {
  const AuditLogPanel({
    super.key,
    required this.entries,
    required this.onClear,
  });

  final List<AuditEntry> entries;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Registo de auditoria',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${entries.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                IconButton(
                  tooltip: 'Limpar registo',
                  onPressed: entries.isEmpty ? null : onClear,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Sem ações registadas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _AuditTile(entry: entries[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = entry.success ? Colors.green.shade600 : scheme.error;

    return ListTile(
      dense: true,
      leading: Icon(
        entry.success ? Icons.check_circle : Icons.error,
        color: color,
      ),
      title: Text(entry.action),
      subtitle: entry.message == null
          ? null
          : Text(
              entry.message!,
              style: TextStyle(
                color: entry.success ? scheme.onSurfaceVariant : scheme.error,
              ),
            ),
      trailing: Text(
        entry.formattedTime,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
