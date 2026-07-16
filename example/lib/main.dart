import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fkiosklite/fkiosklite.dart';

import 'models/audit_entry.dart';
import 'widgets/action_section.dart';
import 'widgets/audit_log_panel.dart';
import 'widgets/status_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.indigo;
    return MaterialApp(
      title: 'fkiosklite',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _kioskPlugin = KioskModePlugin();
  final _updatePlugin = SilentUpdatePlugin();

  /// Package de demonstração usado nas ações de gestão de apps.
  static const _demoPackage = 'com.android.chrome';
  static const _demoApkUrl = 'https://example.com/app-release.apk';

  bool _isDeviceOwner = false;
  bool _isInKioskMode = false;
  bool _canSilentInstall = false;
  bool _busy = false;
  Map<String, String> _versionInfo = const {};
  UpdateStatus? _updateStatus;

  final List<AuditEntry> _log = [];

  StreamSubscription<bool>? _kioskSub;
  StreamSubscription<UpdateStatus>? _updateSub;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _kioskSub = _kioskPlugin.onKioskModeChanged.listen((inKiosk) {
      if (mounted) setState(() => _isInKioskMode = inKiosk);
    });
    _updateSub = _updatePlugin.onUpdateStatus.listen((status) {
      if (mounted) setState(() => _updateStatus = status);
    });
  }

  @override
  void dispose() {
    _kioskSub?.cancel();
    _updateSub?.cancel();
    super.dispose();
  }

  void _addEntry(AuditEntry entry) {
    final tag = entry.success ? 'OK' : 'ERRO';
    final detail = entry.message == null ? '' : ' — ${entry.message}';
    debugPrint('[fkiosklite] $tag ${entry.formattedTime} ${entry.action}$detail');
    if (!mounted) return;
    setState(() => _log.insert(0, entry));
  }

  /// Executa uma ação do plugin, regista o resultado na auditoria e trata erros.
  /// O retorno da closure é usado como detalhe da entrada de sucesso.
  Future<void> _runAction(
    String label,
    Future<String?> Function() action,
  ) async {
    setState(() => _busy = true);
    try {
      final detail = await action();
      _addEntry(AuditEntry.success(label, detail));
    } catch (e) {
      _addEntry(AuditEntry.failure(label, e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshStatus() {
    return _runAction('Atualizar estado', () async {
      final owner = await _kioskPlugin.isDeviceOwner();
      final kiosk = await _kioskPlugin.isInKioskMode();
      final silent = await _updatePlugin.canSilentInstall();
      final version = await _updatePlugin.getVersionInfo();
      if (mounted) {
        setState(() {
          _isDeviceOwner = owner;
          _isInKioskMode = kiosk;
          _canSilentInstall = silent;
          _versionInfo = version;
        });
      }
      return 'Owner: $owner · Kiosk: $kiosk · Silent: $silent';
    });
  }

  /// Lança um erro se o utilizador cancelar, interrompendo a ação destrutiva.
  Future<void> _confirmDestructive(String title, String body) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) throw Exception('Cancelado pelo utilizador');
  }

  @override
  Widget build(BuildContext context) {
    // Ativa apenas quando somos Device Owner e nenhuma ação está em curso.
    final enabled = _isDeviceOwner && !_busy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('fkiosklite'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StatusCard(
                  isDeviceOwner: _isDeviceOwner,
                  isInKioskMode: _isInKioskMode,
                  canSilentInstall: _canSilentInstall,
                  versionInfo: _versionInfo,
                ),
                if (_updateStatus != null) ...[
                  const SizedBox(height: 12),
                  _UpdateBanner(status: _updateStatus!),
                ],
                const SizedBox(height: 12),
                if (!_isDeviceOwner) ...[
                  const _NotOwnerBanner(),
                  const SizedBox(height: 12),
                ],
                ActionSection(
                  title: 'Kiosk Mode',
                  icon: Icons.lock,
                  actions: [
                    ActionItem(
                      label: _isInKioskMode
                          ? 'Desativar kiosk'
                          : 'Ativar kiosk',
                      icon: _isInKioskMode ? Icons.lock_open : Icons.lock,
                      onPressed: enabled ? _toggleKiosk : null,
                    ),
                    ActionItem(
                      label: 'Definir funcionalidades',
                      icon: Icons.tune,
                      onPressed: enabled ? _setKioskFeatures : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ActionSection(
                  title: 'Energia / Dispositivo',
                  icon: Icons.power_settings_new,
                  actions: [
                    ActionItem(
                      label: 'Reiniciar',
                      icon: Icons.restart_alt,
                      onPressed: enabled ? _rebootDevice : null,
                    ),
                    ActionItem(
                      label: 'Desligar',
                      icon: Icons.power_off,
                      onPressed: enabled ? _shutdownDevice : null,
                    ),
                    ActionItem(
                      label: 'Ativar auto-start',
                      icon: Icons.play_circle_outline,
                      onPressed: enabled ? _enableAutoStart : null,
                    ),
                    ActionItem(
                      label: 'Desativar auto-start',
                      icon: Icons.pause_circle_outline,
                      onPressed: enabled ? _disableAutoStart : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ActionSection(
                  title: 'Atualizações',
                  icon: Icons.system_update,
                  actions: [
                    ActionItem(
                      label: 'Pode instalar em silêncio?',
                      icon: Icons.help_outline,
                      onPressed: !_busy ? _checkCanSilentInstall : null,
                    ),
                    ActionItem(
                      label: 'Info de versão',
                      icon: Icons.numbers,
                      onPressed: !_busy ? _getVersionInfo : null,
                    ),
                    ActionItem(
                      label: 'Verificar atualização',
                      icon: Icons.cloud_sync,
                      onPressed: enabled ? _checkForUpdate : null,
                    ),
                    ActionItem(
                      label: 'Instalar de URL',
                      icon: Icons.download,
                      onPressed: enabled ? _installFromUrl : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ActionSection(
                  title: 'Gestão de Apps',
                  icon: Icons.apps,
                  actions: [
                    ActionItem(
                      label: 'Ocultar app demo',
                      icon: Icons.visibility_off,
                      onPressed: enabled ? () => _setAppHidden(true) : null,
                    ),
                    ActionItem(
                      label: 'Mostrar app demo',
                      icon: Icons.visibility,
                      onPressed: enabled ? () => _setAppHidden(false) : null,
                    ),
                    ActionItem(
                      label: 'Desinstalar (kiosk)',
                      icon: Icons.delete_sweep,
                      onPressed: enabled ? _uninstallApp : null,
                    ),
                    ActionItem(
                      label: 'Desinstalar (silent)',
                      icon: Icons.delete_forever,
                      onPressed: enabled ? _uninstallPackage : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ActionSection(
                  title: 'Zona de perigo',
                  icon: Icons.dangerous,
                  actions: [
                    ActionItem(
                      label: 'Remover Device Owner',
                      icon: Icons.no_accounts,
                      destructive: true,
                      onPressed: enabled ? _clearDeviceOwner : null,
                    ),
                    ActionItem(
                      label: 'Factory reset',
                      icon: Icons.delete_forever,
                      destructive: true,
                      onPressed: enabled ? _wipeData : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _refreshStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar estado'),
                ),
                const SizedBox(height: 16),
                AuditLogPanel(
                  entries: _log,
                  onClear: () => setState(_log.clear),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Kiosk ---------------------------------------------------------------

  Future<void> _toggleKiosk() => _runAction(
        _isInKioskMode ? 'Desativar kiosk' : 'Ativar kiosk',
        () async {
          if (_isInKioskMode) {
            await _kioskPlugin.disableKioskMode();
          } else {
            await _kioskPlugin.enableKioskMode(
              config: const KioskConfig(showStatusBar: true),
            );
          }
          final kiosk = await _kioskPlugin.isInKioskMode();
          if (mounted) setState(() => _isInKioskMode = kiosk);
          return null;
        },
      );

  Future<void> _setKioskFeatures() => _runAction(
        'Definir funcionalidades kiosk',
        () async {
          await _kioskPlugin.setKioskFeatures(
            {KioskFeature.systemInfo, KioskFeature.notifications},
          );
          return 'systemInfo + notifications';
        },
      );

  // --- Energia / Dispositivo ----------------------------------------------

  Future<void> _rebootDevice() => _runAction(
        'Reiniciar dispositivo',
        () async {
          await _kioskPlugin.rebootDevice();
          return null;
        },
      );

  Future<void> _shutdownDevice() => _runAction(
        'Desligar dispositivo',
        () async {
          await _kioskPlugin.shutdownDevice();
          return null;
        },
      );

  Future<void> _enableAutoStart() => _runAction(
        'Ativar auto-start',
        () async {
          await _kioskPlugin.enableAutoStart();
          return null;
        },
      );

  Future<void> _disableAutoStart() => _runAction(
        'Desativar auto-start',
        () async {
          await _kioskPlugin.disableAutoStart();
          return null;
        },
      );

  // --- Atualizações --------------------------------------------------------

  Future<void> _checkCanSilentInstall() => _runAction(
        'Verificar silent install',
        () async {
          final can = await _updatePlugin.canSilentInstall();
          if (mounted) setState(() => _canSilentInstall = can);
          return can ? 'Disponível' : 'Indisponível';
        },
      );

  Future<void> _getVersionInfo() => _runAction(
        'Obter info de versão',
        () async {
          final info = await _updatePlugin.getVersionInfo();
          if (mounted) setState(() => _versionInfo = info);
          return info.entries.map((e) => '${e.key}=${e.value}').join(' · ');
        },
      );

  Future<void> _checkForUpdate() => _runAction(
        'Verificar atualização',
        () async {
          final info = await _updatePlugin.checkForUpdate();
          if (info == null) return 'Sem atualização disponível';
          return 'v${info.version} (${info.versionCode})';
        },
      );

  Future<void> _installFromUrl() => _runAction(
        'Instalar de URL',
        () async {
          final session = await _updatePlugin.installFromUrl(_demoApkUrl);
          return 'Sessão #$session';
        },
      );

  // --- Gestão de Apps ------------------------------------------------------

  Future<void> _setAppHidden(bool hidden) => _runAction(
        hidden ? 'Ocultar app demo' : 'Mostrar app demo',
        () async {
          final ok = await _kioskPlugin.setAppHidden(
            _demoPackage,
            hidden: hidden,
          );
          return ok ? 'OK ($_demoPackage)' : 'Falhou ($_demoPackage)';
        },
      );

  Future<void> _uninstallApp() => _runAction(
        'Desinstalar app (kiosk)',
        () async {
          await _kioskPlugin.uninstallApp(_demoPackage);
          return _demoPackage;
        },
      );

  Future<void> _uninstallPackage() => _runAction(
        'Desinstalar package (silent)',
        () async {
          final ok = await _updatePlugin.uninstallPackage(_demoPackage);
          return ok ? 'OK ($_demoPackage)' : 'Falhou ($_demoPackage)';
        },
      );

  // --- Zona de perigo ------------------------------------------------------

  Future<void> _clearDeviceOwner() => _runAction(
        'Remover Device Owner',
        () async {
          await _confirmDestructive(
            'Remover Device Owner?',
            'Isto desativa todas as funcionalidades MDM. A app deixa de '
                'controlar o dispositivo.',
          );
          await _kioskPlugin.clearDeviceOwner();
          if (mounted) setState(() => _isDeviceOwner = false);
          return null;
        },
      );

  Future<void> _wipeData() => _runAction(
        'Factory reset',
        () async {
          await _confirmDestructive(
            'Factory reset?',
            'Ação IRREVERSÍVEL. Todos os dados do dispositivo serão apagados.',
          );
          await _kioskPlugin.wipeData();
          return null;
        },
      );
}

/// Aviso apresentado quando a app não é Device Owner.
class _NotOwnerBanner extends StatelessWidget {
  const _NotOwnerBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context)
          .colorScheme
          .errorContainer
          .withValues(alpha: 0.5),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'A app não é Device Owner. As ações MDM estão desativadas.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner com o progresso da atualização em curso.
class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.status});

  final UpdateStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failed = status.state == UpdateState.failed;
    final done = status.state == UpdateState.success;
    final showProgress = !failed && !done;

    final color = failed
        ? scheme.error
        : done
            ? Colors.green.shade600
            : scheme.primary;

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  failed
                      ? Icons.error
                      : done
                          ? Icons.check_circle
                          : Icons.downloading,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Atualização: ${status.state.name} '
                    '(${(status.progress * 100).toInt()}%)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: status.progress),
            ],
            if (status.error != null) ...[
              const SizedBox(height: 8),
              Text(
                status.error!,
                style: TextStyle(color: scheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
