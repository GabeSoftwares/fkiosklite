import 'package:flutter_test/flutter_test.dart';
import 'package:fkiosk/fkiosk.dart';

void main() {
  group('KioskConfig', () {
    test('toMap returns correct defaults', () {
      const config = KioskConfig();
      final map = config.toMap();
      expect(map['showStatusBar'], false);
      expect(map['showNotifications'], false);
      expect(map['enableHomeButton'], false);
      expect(map['enableOverviewButton'], false);
      expect(map['enablePowerButton'], false);
      expect(map['allowedPackages'], <String>[]);
    });

    test('toMap returns custom values', () {
      const config = KioskConfig(
        showStatusBar: true,
        showNotifications: true,
        enableHomeButton: true,
        enableOverviewButton: true,
        enablePowerButton: true,
        allowedPackages: ['com.example.other'],
      );
      final map = config.toMap();
      expect(map['showStatusBar'], true);
      expect(map['showNotifications'], true);
      expect(map['enableHomeButton'], true);
      expect(map['enableOverviewButton'], true);
      expect(map['enablePowerButton'], true);
      expect(map['allowedPackages'], ['com.example.other']);
    });

    test('fromMap creates correct instance', () {
      final config = KioskConfig.fromMap({
        'showStatusBar': true,
        'enableHomeButton': true,
        'allowedPackages': ['com.test'],
      });
      expect(config.showStatusBar, true);
      expect(config.showNotifications, false);
      expect(config.enableHomeButton, true);
      expect(config.allowedPackages, ['com.test']);
    });

    test('fromMap handles missing keys', () {
      final config = KioskConfig.fromMap({});
      expect(config.showStatusBar, false);
      expect(config.allowedPackages, <String>[]);
    });
  });

  group('KioskFeature', () {
    test('has correct values', () {
      expect(KioskFeature.systemInfo.value, 1);
      expect(KioskFeature.notifications.value, 2);
      expect(KioskFeature.home.value, 4);
      expect(KioskFeature.overview.value, 8);
      expect(KioskFeature.globalActions.value, 16);
      expect(KioskFeature.keyguard.value, 32);
    });
  });

  group('UpdateInfo', () {
    test('fromMap creates correct instance', () {
      final info = UpdateInfo.fromMap({
        'version': '2.0.0',
        'downloadUrl': 'https://example.com/app.apk',
        'fileSize': 1024000,
        'checksum': 'abc123',
        'mandatory': true,
      });
      expect(info.version, '2.0.0');
      expect(info.downloadUrl, 'https://example.com/app.apk');
      expect(info.fileSize, 1024000);
      expect(info.checksum, 'abc123');
      expect(info.mandatory, true);
    });

    test('fromMap defaults mandatory to false', () {
      final info = UpdateInfo.fromMap({
        'version': '1.0.0',
        'downloadUrl': 'https://example.com/app.apk',
        'fileSize': 500,
        'checksum': 'xyz',
      });
      expect(info.mandatory, false);
    });

    test('toMap round-trips correctly', () {
      const original = UpdateInfo(
        version: '1.5.0',
        downloadUrl: 'https://example.com/update.apk',
        fileSize: 2048,
        checksum: 'sha256hash',
        mandatory: true,
      );
      final restored = UpdateInfo.fromMap(original.toMap());
      expect(restored.version, original.version);
      expect(restored.downloadUrl, original.downloadUrl);
      expect(restored.fileSize, original.fileSize);
      expect(restored.checksum, original.checksum);
      expect(restored.mandatory, original.mandatory);
    });
  });

  group('UpdateStatus', () {
    test('fromMap creates correct instance', () {
      final status = UpdateStatus.fromMap({
        'state': 'downloading',
        'sessionId': 42,
        'progress': 0.5,
        'error': null,
      });
      expect(status.state, UpdateState.downloading);
      expect(status.sessionId, 42);
      expect(status.progress, 0.5);
      expect(status.error, isNull);
    });

    test('fromMap handles error state', () {
      final status = UpdateStatus.fromMap({
        'state': 'failed',
        'sessionId': 1,
        'progress': 0.0,
        'error': 'Install failed',
      });
      expect(status.state, UpdateState.failed);
      expect(status.error, 'Install failed');
    });

    test('toMap round-trips correctly', () {
      const original = UpdateStatus(
        state: UpdateState.installing,
        sessionId: 7,
        progress: 0.75,
      );
      final restored = UpdateStatus.fromMap(original.toMap());
      expect(restored.state, original.state);
      expect(restored.sessionId, original.sessionId);
      expect(restored.progress, original.progress);
      expect(restored.error, original.error);
    });
  });

  group('DeviceInfo', () {
    test('fromMap creates correct instance', () {
      final info = DeviceInfo.fromMap({
        'isDeviceOwner': true,
        'isInKioskMode': false,
        'packageName': 'com.test.app',
        'versionName': '1.0.0',
        'versionCode': 1,
        'androidSdkVersion': 33,
      });
      expect(info.isDeviceOwner, true);
      expect(info.isInKioskMode, false);
      expect(info.packageName, 'com.test.app');
      expect(info.versionName, '1.0.0');
      expect(info.versionCode, 1);
      expect(info.androidSdkVersion, 33);
    });

    test('fromMap handles missing keys', () {
      final info = DeviceInfo.fromMap({});
      expect(info.isDeviceOwner, false);
      expect(info.isInKioskMode, false);
      expect(info.packageName, '');
      expect(info.versionName, '');
      expect(info.versionCode, 0);
      expect(info.androidSdkVersion, 0);
    });

    test('toMap round-trips correctly', () {
      const original = DeviceInfo(
        isDeviceOwner: true,
        isInKioskMode: true,
        packageName: 'ao.gabrielvieira.fkiosk',
        versionName: '2.0.0',
        versionCode: 5,
        androidSdkVersion: 34,
      );
      final restored = DeviceInfo.fromMap(original.toMap());
      expect(restored.isDeviceOwner, original.isDeviceOwner);
      expect(restored.isInKioskMode, original.isInKioskMode);
      expect(restored.packageName, original.packageName);
      expect(restored.versionName, original.versionName);
      expect(restored.versionCode, original.versionCode);
      expect(restored.androidSdkVersion, original.androidSdkVersion);
    });
  });
}
