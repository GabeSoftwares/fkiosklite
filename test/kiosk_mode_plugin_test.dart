import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fkiosk/fkiosk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ao.gabrielvieira.fkiosk/kiosk_mode');
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
        case 'enableKioskMode':
        case 'disableKioskMode':
        case 'setKioskFeatures':
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
}
