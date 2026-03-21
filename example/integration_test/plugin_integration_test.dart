import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fkiosk/fkiosk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isDeviceOwner returns a bool', (WidgetTester tester) async {
    final plugin = KioskModePlugin();
    final result = await plugin.isDeviceOwner();
    expect(result, isA<bool>());
  });
}
