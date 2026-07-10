import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fkiosklite/fkiosklite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ao.gabrielvieira.fkiosklite/silent_update');
  final plugin = SilentUpdatePlugin();
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      switch (call.method) {
        case 'canSilentInstall':
          return true;
        case 'installApk':
          return 42;
        case 'installFromUrl':
          return 43;
        case 'uninstallPackage':
          return true;
        case 'getVersionInfo':
          return {
            'packageName': 'com.test',
            'versionName': '1.0.0',
            'versionCode': '1',
          };
        case 'checkForUpdate':
          return {
            'version': '2.0.0',
            'downloadUrl': 'https://example.com/app.apk',
            'fileSize': 1024,
            'checksum': 'abc',
            'mandatory': false,
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('canSilentInstall returns true', () async {
    final result = await plugin.canSilentInstall();
    expect(result, true);
    expect(log.last.method, 'canSilentInstall');
  });

  test('installApk returns session id', () async {
    final result = await plugin.installApk('/path/to/app.apk');
    expect(result, 42);
    expect(log.last.method, 'installApk');
    final args = log.last.arguments as Map;
    expect(args['apkPath'], '/path/to/app.apk');
  });

  test('installFromUrl returns session id', () async {
    final result = await plugin.installFromUrl(
      'https://example.com/app.apk',
      headers: {'Authorization': 'Bearer token'},
    );
    expect(result, 43);
    expect(log.last.method, 'installFromUrl');
    final args = log.last.arguments as Map;
    expect(args['url'], 'https://example.com/app.apk');
    expect(args['headers'], {'Authorization': 'Bearer token'});
  });

  test('uninstallPackage returns true', () async {
    final result = await plugin.uninstallPackage('com.other.app');
    expect(result, true);
    expect(log.last.method, 'uninstallPackage');
    final args = log.last.arguments as Map;
    expect(args['packageName'], 'com.other.app');
  });

  test('getVersionInfo returns version map', () async {
    final result = await plugin.getVersionInfo();
    expect(result['packageName'], 'com.test');
    expect(result['versionName'], '1.0.0');
    expect(log.last.method, 'getVersionInfo');
  });

  test('checkForUpdate returns UpdateInfo', () async {
    final result = await plugin.checkForUpdate(url: 'https://example.com/check');
    expect(result, isNotNull);
    expect(result!.version, '2.0.0');
    expect(result.downloadUrl, 'https://example.com/app.apk');
    expect(result.fileSize, 1024);
    expect(result.checksum, 'abc');
    expect(result.mandatory, false);
    expect(log.last.method, 'checkForUpdate');
  });
}
