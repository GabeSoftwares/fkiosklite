import 'package:flutter/services.dart';

import 'models/update_status.dart';

/// Manages silent (background) app updates on Device Owner managed devices.
class SilentUpdatePlugin {
  static const _channel = MethodChannel('ao.gabrielvieira.fkiosk/silent_update');
  static const _eventChannel = EventChannel('ao.gabrielvieira.fkiosk/update_events');

  /// Check if silent install is available (requires Device Owner).
  Future<bool> canSilentInstall() async {
    return await _channel.invokeMethod<bool>('canSilentInstall') ?? false;
  }

  /// Install an APK silently from a local file path.
  ///
  /// The APK must already be downloaded to the device.
  /// Returns a session ID to track installation progress.
  Future<int> installApk(String apkPath) async {
    return await _channel.invokeMethod<int>('installApk', {
          'apkPath': apkPath,
        }) ??
        -1;
  }

  /// Download and install an APK from a URL silently.
  ///
  /// Handles download + installation in one step.
  Future<int> installFromUrl(String url,
      {Map<String, String>? headers}) async {
    return await _channel.invokeMethod<int>('installFromUrl', {
          'url': url,
          'headers': headers,
        }) ??
        -1;
  }

  /// Uninstall a package silently.
  Future<bool> uninstallPackage(String packageName) async {
    return await _channel.invokeMethod<bool>(
            'uninstallPackage', {'packageName': packageName}) ??
        false;
  }

  /// Get current app version info.
  Future<Map<String, String>> getVersionInfo() async {
    final result = await _channel.invokeMethod<Map>('getVersionInfo');
    return result?.cast<String, String>() ?? {};
  }

  /// Check for updates from the configured update server.
  Future<UpdateInfo?> checkForUpdate({String? url}) async {
    final result = await _channel.invokeMethod<Map>('checkForUpdate', {
      if (url != null) 'url': url,
    });
    if (result == null) return null;
    return UpdateInfo.fromMap(result.cast<String, dynamic>());
  }

  /// Stream of update/installation progress events.
  Stream<UpdateStatus> get onUpdateStatus {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) =>
            UpdateStatus.fromMap(Map<String, dynamic>.from(event as Map)));
  }
}
