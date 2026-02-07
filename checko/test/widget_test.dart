import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checko/main.dart';
import 'package:checko/providers/data_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize the data provider
    final dataProvider = DataProvider();
    await dataProvider.initialize();

    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp(dataProvider: dataProvider));

    // Verify app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
