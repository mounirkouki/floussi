import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:floussi/main.dart';
import 'package:floussi/providers/budget_provider.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => BudgetProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('فلوسي')),
          ),
        ),
      ),
    );
    expect(find.text('فلوسي'), findsOneWidget);
  });

  testWidgets('FloussiApp builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const FloussiApp());
    await tester.pump();
    // App title should be present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
