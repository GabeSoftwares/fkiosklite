import 'package:flutter/material.dart';

/// Cartão de estado no topo: Device Owner, Kiosk Mode e versão da app.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.isDeviceOwner,
    required this.isInKioskMode,
    required this.canSilentInstall,
    required this.versionInfo,
  });

  final bool isDeviceOwner;
  final bool isInKioskMode;
  final bool canSilentInstall;
  final Map<String, String> versionInfo;

  @override
  Widget build(BuildContext context) {
    final version = versionInfo['versionName'] ??
        versionInfo['version'] ??
        versionInfo.values.firstOrNull ??
        '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado do dispositivo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: 'Device Owner',
                  active: isDeviceOwner,
                ),
                _StatusChip(
                  label: 'Kiosk Mode',
                  active: isInKioskMode,
                ),
                _StatusChip(
                  label: 'Silent Install',
                  active: canSilentInstall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Versão: $version',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.outline;

    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        color: color,
        size: 18,
      ),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: active
          ? scheme.primaryContainer.withValues(alpha: 0.3)
          : scheme.surfaceContainerHighest,
    );
  }
}
