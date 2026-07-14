import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Onboarding shown when the app opens.
///
/// The village illustration (assets/images/background.jpg) fills the whole
/// screen; a dark gradient is layered over its lower part so the white text
/// stays readable on top of the picture. If the image file is missing, a
/// plain teal background is shown instead, so the app never crashes while
/// artwork is being collected.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _WelcomePage(
      title: 'Welcome to Ojha Paath Sigi',
      body: 'Learn to write the Chakma script, one letter at a time.',
    ),
    _WelcomePage(
      title: 'Trace with your finger',
      body: 'Pick a letter, then draw it on the board just like writing on paper.',
    ),
    _WelcomePage(
      title: 'Get instant feedback',
      body: 'The app checks your writing and tells you how close you got.',
    ),
  ];

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
            // Shown while the picture is missing from assets/images/.
            errorBuilder: (_, __, ___) =>
                ColoredBox(color: theme.colorScheme.primary),
          ),
          // Dark gradient: subtle at the top (for the Skip button), strong at
          // the bottom where the text sits — keeps white text readable
          // without hiding the picture.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black38, Colors.transparent, Colors.black87],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: _pages,
                  ),
                ),
                // Page indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLastPage
                          ? _finish
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              ),
                      child: Text(isLastPage ? 'Get started' : 'Next'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One page of the onboarding: text pinned to the bottom, over the gradient.
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
