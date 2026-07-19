import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ojha_phat_sigon/main.dart';

void main() {
  setUp(() {
    // Gives shared_preferences a fake in-memory store: tests have no real
    // device storage, and HomeScreen reads progress the moment it opens.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('First launch starts on the welcome screen', (tester) async {
    await tester.pumpWidget(const OjhaPhatSigonApp(showOnboarding: true));

    expect(find.text('Welcome to Ojha Paath Sigi'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Later launches skip onboarding and start on home',
      (tester) async {
    await tester.pumpWidget(const OjhaPhatSigonApp(showOnboarding: false));
    await tester.pump(); // let the async progress load finish

    expect(find.text('What do you want to practice?'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}
