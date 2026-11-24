import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_development_assignment_group_12/UserDashboard/UserDashboard.dart';

void main() {
  testWidgets('CampusSafe student prototype starts', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('CampusSafe'), findsOneWidget);
    expect(find.text('Edmund Chai En Yun'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('campus-map-placeholder')),
      findsOneWidget,
    );
    for (final tab in ['home', 'reports', 'chat', 'ranking']) {
      expect(find.byKey(ValueKey('nav-$tab')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
