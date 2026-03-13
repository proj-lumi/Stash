import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/main.dart';

void main() {
  testWidgets('App builds with MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BudgetApp()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
