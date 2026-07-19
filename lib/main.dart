import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  // main is async now (we read a preference before the first frame), so
  // Flutter's plumbing must be initialised by hand — runApp normally does it.
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool(seenOnboardingPrefsKey) ?? false;
  runApp(OjhaPhatSigonApp(showOnboarding: !seenOnboarding));
}

class OjhaPhatSigonApp extends StatelessWidget {
  const OjhaPhatSigonApp({super.key, this.showOnboarding = true});

  /// Whether to open on the onboarding slides (first launch) or go
  /// straight to the home screen (every later launch).
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B7A6E), // calm teal — easy on the eyes for a learning app
      ),
    );

    return MaterialApp(
      title: 'Ojha Paath Sigi',
      debugShowCheckedModeBanner: false,
      // fontFamilyFallback: Latin text keeps the default font; only
      // characters it lacks (the Chakma block) fall through to the bundled
      // Noto Sans Chakma, so glyphs render even on devices without a
      // Chakma system font.
      theme: theme.copyWith(
        textTheme: theme.textTheme
            .apply(fontFamilyFallback: const ['NotoSansChakma']),
        primaryTextTheme: theme.primaryTextTheme
            .apply(fontFamilyFallback: const ['NotoSansChakma']),
      ),
      home: showOnboarding ? const WelcomeScreen() : const HomeScreen(),
    );
  }
}
