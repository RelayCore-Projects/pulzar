import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulzar/app.dart';
import 'package:pulzar/app_info.dart';

Finder _navLabel(String label) => find.descendant(
      of: find.byKey(const Key('main-navigation')),
      matching: find.text(label),
    );

void main() {
  testWidgets('The Log view is shown on start', (tester) async {
    await tester.pumpWidget(const PulzarApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeholder-log')), findsOneWidget);
    expect(find.byKey(const Key('add-button')), findsOneWidget);
    expect(_navLabel('Log'), findsOneWidget);
    expect(_navLabel('Table'), findsOneWidget);
    expect(_navLabel('Charts'), findsOneWidget);
  });

  testWidgets('The navigation bar switches between views', (tester) async {
    await tester.pumpWidget(const PulzarApp());
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Table'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placeholder-table')), findsOneWidget);
    expect(find.byKey(const Key('add-button')), findsNothing);

    await tester.tap(_navLabel('Charts'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placeholder-charts')), findsOneWidget);
  });

  testWidgets('About shows the medical disclaimer (FR-16)', (tester) async {
    await tester.pumpWidget(const PulzarApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-tile')));
    await tester.pumpAndSettle();

    expect(find.text(AppInfo.disclaimer), findsOneWidget);
    expect(find.textContaining('MIT'), findsOneWidget);
  });

  test('Default reference values are 135/85 mmHg (FR-10)', () {
    expect(AppInfo.defaultRefSystolic, 135);
    expect(AppInfo.defaultRefDiastolic, 85);
  });
}
