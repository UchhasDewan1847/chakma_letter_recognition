import 'package:flutter_test/flutter_test.dart';

import 'package:ojha_phat_sigon/main.dart';

void main() {
  testWidgets('App starts on the welcome screen', (tester) async {
    await tester.pumpWidget(const OjhaPhatSigonApp());

    expect(find.text('Welcome to Ojha Paath Sigi'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
