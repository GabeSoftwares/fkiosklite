import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fkiosklite/fkiosklite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ao.gabrielvieira.fkiosklite/kiosk_mode');
  final plugin = KioskModePlugin();
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      switch (call.method) {
        case 'isDeviceOwner':
          return true;
        case 'isInKioskMode':
          return false;
        case 'canShutdown':
          return true;
        case 'enableKioskMode':
        case 'disableKioskMode':
        case 'setKioskFeatures':
        case 'shutdownDevice':
        case 'rebootDevice':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isDeviceOwner returns true', () async {
    final result = await plugin.isDeviceOwner();
    expect(result, true);
    expect(log.last.method, 'isDeviceOwner');
  });

  test('isInKioskMode returns false', () async {
    final result = await plugin.isInKioskMode();
    expect(result, false);
    expect(log.last.method, 'isInKioskMode');
  });

  test('enableKioskMode sends config', () async {
    const config = KioskConfig(
      showStatusBar: true,
      allowedPackages: ['com.other'],
    );
    await plugin.enableKioskMode(config: config);
    expect(log.last.method, 'enableKioskMode');
    final args = log.last.arguments as Map;
    expect(args['showStatusBar'], true);
    expect(args['allowedPackages'], ['com.other']);
  });

  test('enableKioskMode without config sends null', () async {
    await plugin.enableKioskMode();
    expect(log.last.method, 'enableKioskMode');
    expect(log.last.arguments, isNull);
  });

  test('disableKioskMode calls correct method', () async {
    await plugin.disableKioskMode();
    expect(log.last.method, 'disableKioskMode');
  });

  test('setKioskFeatures sends feature values', () async {
    await plugin.setKioskFeatures({
      KioskFeature.systemInfo,
      KioskFeature.home,
    });
    expect(log.last.method, 'setKioskFeatures');
    final args = log.last.arguments as List;
    expect(args, containsAll([1, 4]));
  });

  test('rebootDevice calls correct method', () async {
    await plugin.rebootDevice();
    expect(log.last.method, 'rebootDevice');
  });

  test('shutdownDevice calls correct method', () async {
    await plugin.shutdownDevice();
    expect(log.last.method, 'shutdownDevice');
  });

  test('canShutdown returns availability', () async {
    final result = await plugin.canShutdown();
    expect(result, true);
    expect(log.last.method, 'canShutdown');
  });
}
