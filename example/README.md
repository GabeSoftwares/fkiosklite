# fkiosklite_example

Demonstrates how to use the fkiosklite plugin.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Enabling Device Owner mode

Every kiosk and silent-update feature in this plugin requires the app to be
**Device Owner**. Device Owner can only be granted on a device/emulator that
has **no accounts configured** (Google account, etc.) — factory reset (or a
fresh emulator) if the device is already provisioned.

### 1. Install the example app without running it

```bash
cd example
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Do not launch the app yet — some OEMs re-add a default account on first
launch, which blocks Device Owner provisioning.

### 2. Set the app as Device Owner via ADB

The example app's `applicationId` (`ao.gabrielvieira.fkiosklite_example`) is
different from the plugin's own package, so the component must be fully
qualified as `<example applicationId>/<plugin package>.dpc.AdminReceiver`:

```bash
adb shell dpm set-device-owner \
  ao.gabrielvieira.fkiosklite_example/ao.gabrielvieira.fkiosklite.dpc.AdminReceiver
```

On success you'll see `Success: Device owner set to package ...`. If it
fails with `Not allowed to set the device owner because there are already
users on the device`, remove all accounts (Settings → Accounts) or wipe the
device/emulator and retry.

### 3. Verify

```bash
adb shell dumpsys device_policy | grep "Device Owner"
```

You can now `flutter run` the example app — `isDeviceOwner()` should return
`true`, unlocking `enableKioskMode`, `setKioskFeatures`, and the silent
update APIs.

### Removing Device Owner (to reset)

```bash
adb shell dpm remove-active-admin \
  ao.gabrielvieira.fkiosklite_example/ao.gabrielvieira.fkiosklite.dpc.AdminReceiver
```

See `ARCHITECTURE.md` at the repo root for the full provisioning reference,
including zero-touch/QR code enrollment for production deployments.
