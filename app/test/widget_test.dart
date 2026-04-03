import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luko/main.dart';

void main() {
  testWidgets('LukoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LukoApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
