import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fkiosklite/fkiosklite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _kioskPlugin = KioskModePlugin();
  final _updatePlugin = SilentUpdatePlugin();

  bool _isDeviceOwner = false;
  bool _isInKioskMode = false;
  String _updateStatus = 'Idle';
  StreamSubscription<bool>? _kioskSub;
  StreamSubscription<UpdateStatus>? _updateSub;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _kioskSub = _kioskPlugin.onKioskModeChanged.listen((inKiosk) {
      if (mounted) setState(() => _isInKioskMode = inKiosk);
    });
    _updateSub = _updatePlugin.onUpdateStatus.listen((status) {
      if (mounted) {
        setState(() {
          _updateStatus =
              '${status.state.name} (${(status.progress * 100).toInt()}%)';
          if (status.error != null) {
            _updateStatus += ' - ${status.error}';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _kioskSub?.cancel();
    _updateSub?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final isOwner = await _kioskPlugin.isDeviceOwner();
    final inKiosk = await _kioskPlugin.isInKioskMode();
    if (mounted) {
      setState(() {
        _isDeviceOwner = isOwner;
        _isInKioskMode = inKiosk;
      });
    }
  }

  Future<void> _toggleKiosk() async {
    if (_isInKioskMode) {
      await _kioskPlugin.disableKioskMode();
    } else {
      await _kioskPlugin.enableKioskMode(
        config: const KioskConfig(showStatusBar: true),
      );
    }
    await _checkStatus();
  }

  Future<void> _rebootDevice() async {
    await _kioskPlugin.rebootDevice();
  }

  Future<void> _shutdownDevice() async {
    await _kioskPlugin.shutdownDevice();
  }

  Future<void> _installFromUrl() async {
    const url = 'https://example.com/app-release.apk';
    await _updatePlugin.installFromUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('fkiosklite Example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device Owner: $_isDeviceOwner'),
              const SizedBox(height: 8),
              Text('Kiosk Mode: $_isInKioskMode'),
              const SizedBox(height: 8),
              Text('Update Status: $_updateStatus'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isDeviceOwner ? _toggleKiosk : null,
                child:
                    Text(_isInKioskMode ? 'Disable Kiosk' : 'Enable Kiosk'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isDeviceOwner ? _installFromUrl : null,
                child: const Text('Install APK from URL'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isDeviceOwner ? _rebootDevice : null,
                child: const Text('Reboot Device'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isDeviceOwner ? _shutdownDevice : null,
                child: const Text('Shutdown Device'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _checkStatus,
                child: const Text('Refresh Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
