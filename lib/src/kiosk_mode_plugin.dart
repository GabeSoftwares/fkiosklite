import 'package:flutter/services.dart';

import 'models/kiosk_config.dart';

/// Controls Android Lock Task (Kiosk) Mode.
class KioskModePlugin {
  static const _channel = MethodChannel('ao.gabrielvieira.fkiosk/kiosk_mode');

  /// Check if the app is currently the Device Owner.
  Future<bool> isDeviceOwner() async {
    return await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;
  }

  /// Check if the device is currently in Lock Task (kiosk) mode.
  Future<bool> isInKioskMode() async {
    return await _channel.invokeMethod<bool>('isInKioskMode') ?? false;
  }

  /// Enter kiosk mode with optional configuration.
  ///
  /// Requires Device Owner privileges. Whitelists the app package
  /// for Lock Task Mode and starts the lock task.
  Future<void> enableKioskMode({KioskConfig? config}) async {
    await _channel.invokeMethod('enableKioskMode', config?.toMap());
  }

  /// Exit kiosk mode.
  ///
  /// Can only be called programmatically or via admin action.
  Future<void> disableKioskMode() async {
    await _channel.invokeMethod('disableKioskMode');
  }

  /// Configure which system UI features are available in kiosk mode.
  /// Android 9+ only.
  Future<void> setKioskFeatures(Set<KioskFeature> features) async {
    await _channel.invokeMethod(
      'setKioskFeatures',
      features.map((f) => f.value).toList(),
    );
  }

  /// Reboot the device. Requires Device Owner privileges.
  Future<void> rebootDevice() async {
    await _channel.invokeMethod('rebootDevice');
  }

  /// Shut down the device. Requires Device Owner privileges.
  Future<void> shutdownDevice() async {
    await _channel.invokeMethod('shutdownDevice');
  }

  /// Enable auto-start on boot. Requires Device Owner privileges.
  Future<void> enableAutoStart() async {
    await _channel.invokeMethod('enableAutoStart');
  }

  /// Disable auto-start on boot.
  Future<void> disableAutoStart() async {
    await _channel.invokeMethod('disableAutoStart');
  }

  /// Stream of kiosk mode state changes.
  Stream<bool> get onKioskModeChanged {
    return const EventChannel('ao.gabrielvieira.fkiosk/kiosk_mode_events')
        .receiveBroadcastStream()
        .map((event) => event as bool);
  }
}
