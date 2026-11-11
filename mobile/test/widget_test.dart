import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livestock_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('starts on the farm overview and navigates to Feed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Kofi'), findsOneWidget);
    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('Use & stock'), findsOneWidget);
    expect(find.text('Cycle impact'), findsOneWidget);
  });

  testWidgets('calculates a feed batch cost against the budget', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FeedCalculatorPage()));

    Future<void> enter(String key, String value) async {
      final field = find.byKey(ValueKey(key));
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    Future<void> setIngredient(String name, String price, String mix) async {
      final key = name.toLowerCase().replaceAll(' ', '-');
      final available = find.byKey(ValueKey('available-$key'));
      await tester.ensureVisible(available);
      await tester.tap(available);
      await tester.pumpAndSettle();
      await enter('price-$key', price);
      await enter('mix-$key', mix);
    }

    await enter('bird-count', '100');
    await enter('days-to-prepare', '2');
    await enter('budget', '280');
    await setIngredient('Maize', '10', '60');
    await setIngredient('Soybean meal', '20', '30');
    await setIngredient('Premixes', '30', '10');

    final calculate = find.byKey(const ValueKey('calculate-feed-cost'));
    await tester.ensureVisible(calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    expect(find.text('20.00 kg for 100 birds over 2 day(s).'), findsOneWidget);
    expect(find.text('GH₵ 300.00'), findsOneWidget);
    expect(find.text('GH₵ 15.00'), findsOneWidget);
    expect(find.text('Over budget by GH₵ 20.00.'), findsOneWidget);
  });
}