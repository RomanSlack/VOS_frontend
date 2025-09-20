import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vos_app/presentation/pages/splash/splash_page.dart';

void main() {
  testWidgets('Splash page shows VOS App title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashPage(),
      ),
    );

    // Verify that splash page shows title
    expect(find.text('VOS App'), findsOneWidget);
  });
}
