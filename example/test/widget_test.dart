import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fkiosklite_example/main.dart';

void main() {
  testWidgets('Renders the main sections and the audit log', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('fkiosklite'), findsWidgets);
    expect(find.text('Estado do dispositivo'), findsOneWidget);
    expect(find.text('Kiosk Mode'), findsWidgets);

    // O painel de auditoria está no fim da lista lazy; faz scroll até ele.
    await tester.dragUntilVisible(
      find.text('Registo de auditoria'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    expect(find.text('Registo de auditoria'), findsOneWidget);
  });

  testWidgets('Actions are disabled when not Device Owner', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('A app não é Device Owner. As ações MDM estão desativadas.'),
        findsOneWidget);

    final disabledButton = find.byWidgetPredicate(
      (w) => w is ButtonStyleButton && w.onPressed == null,
    );
    expect(disabledButton, findsWidgets);
  });
}
