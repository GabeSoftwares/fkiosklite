# fkiosk

A Flutter plugin for **Android Enterprise** kiosk mode and silent APK updates. Designed for COSU (Corporate Owned, Single Use) deployments where devices need to be locked to a single app with remote update capabilities.

## Features

- **Kiosk Mode** — Lock the device into single-app mode using Android's Lock Task Mode API (`DevicePolicyManager`). Control system UI elements like status bar, navigation buttons, and notifications.
- **Silent Updates** — Download and install APKs silently without user interaction via the `PackageInstaller` API. Track download/installation progress through streams.

## Requirements

- Android 11+ (API 30+)
- Flutter 3.10.0+
- Device Owner privileges (set up via zero-touch provisioning or manual DPC enrollment)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  fkiosk:
    git:
      url: https://github.com/gabrielvieira/fkiosk.git
```

## Usage

### Kiosk Mode

```dart
import 'package:fkiosk/fkiosk.dart';

final kiosk = KioskModePlugin();

// Check if app has Device Owner privileges
final isOwner = await kiosk.isDeviceOwner();

// Enable kiosk mode with configuration
await kiosk.enableKioskMode(
  config: const KioskConfig(
    showStatusBar: true,
    showNotifications: false,
    enableHomeButton: false,
  ),
);

// Listen to kiosk mode state changes
kiosk.onKioskModeChanged.listen((isInKiosk) {
  print('Kiosk mode: $isInKiosk');
});

// Disable kiosk mode
await kiosk.disableKioskMode();
```

### Silent Updates

```dart
import 'package:fkiosk/fkiosk.dart';

final updater = SilentUpdatePlugin();

// Check if silent install is available
final canInstall = await updater.canSilentInstall();

// Install APK from URL
final sessionId = await updater.installFromUrl(
  'https://example.com/app-release.apk',
);

// Track progress
updater.onUpdateStatus.listen((status) {
  print('${status.state.name}: ${(status.progress * 100).toInt()}%');
});

// Install from local file
await updater.installApk('/path/to/app.apk');

// Uninstall a package
await updater.uninstallPackage('com.example.app');
```

## KioskConfig Options

| Option | Default | Description |
|--------|---------|-------------|
| `showStatusBar` | `false` | Show time, battery, connectivity |
| `showNotifications` | `false` | Allow system notifications |
| `enableHomeButton` | `false` | Allow home button |
| `enableOverviewButton` | `false` | Allow recent apps overview |
| `enablePowerButton` | `false` | Allow power button dialog |
| `allowedPackages` | `[]` | Additional packages allowed alongside kiosk app |

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for technical details on platform channels, Android implementation, and Device Policy Controller setup.

## License

See [LICENSE](LICENSE) for details.
