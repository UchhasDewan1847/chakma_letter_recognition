import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

/// One long scrollable page explaining how to use the app, in English.
///
/// Reachable any time from the paper icon on the home screen — this is the
/// permanent replacement for the onboarding slides, which are only shown on
/// the very first launch.
class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        // Transparent so the blurred illustration shows through.
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('How to use'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                'Learning to write Chakma, step by step',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Everything you need to know is on this page. '
                'You can come back to it any time from the paper icon '
                'on the home screen.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              const _InstructionSection(
                icon: Icons.category_outlined,
                title: '1. Pick a category',
                body: 'From the home screen choose what to practice: '
                    'Consonants (32 letters), Numbers (0–9), or Vowels. '
                    'Each category has its own practice grid.',
              ),
              const _InstructionSection(
                icon: Icons.grid_view_outlined,
                title: '2. Choose a character',
                body: 'Tap any character in the grid to open its practice '
                    'board. Its name is written under each glyph, so you '
                    'learn the sound along with the shape.',
              ),
              const _InstructionSection(
                icon: Icons.draw_outlined,
                title: '3. Look first, then draw',
                body: 'The character you should copy is shown at the top. '
                    'Study its shape for a moment, then draw it on the '
                    'white board with your finger — just like writing on '
                    'paper.',
              ),
              const _InstructionSection(
                icon: Icons.zoom_out_map,
                title: 'Do: draw big and centered',
                body: 'Use the whole board! Big, centered writing is much '
                    'easier for the app to read than a small doodle in a '
                    'corner.',
              ),
              const _InstructionSection(
                icon: Icons.looks_one_outlined,
                title: 'Do: one character at a time',
                body: 'Write only the single character you are practicing. '
                    'Extra marks, dots or a second character will confuse '
                    'the checker.',
              ),
              const _InstructionSection(
                icon: Icons.gesture,
                title: 'Do: follow the sample\'s strokes',
                body: 'Try to match the sample\'s proportions — where lines '
                    'curve, where they join, which parts are tall or wide. '
                    'Slow and careful beats fast and messy.',
              ),
              const _InstructionSection(
                icon: Icons.undo,
                title: 'Fixing mistakes',
                body: 'The undo button removes your last stroke; the bin '
                    'button wipes the board clean. Redrawing a character '
                    'from scratch is great practice, not a failure!',
              ),
              const _InstructionSection(
                icon: Icons.check_circle_outline,
                title: '4. Check your writing',
                body: 'Tap "Check my writing" when you are done. The app '
                    'compares your drawing with the character and tells '
                    'you if it matches. If it says it is not close enough, '
                    'look at the sample again and give it another try — '
                    'every attempt trains your hand.',
              ),
              const _InstructionSection(
                icon: Icons.auto_awesome,
                title: 'Free drawing',
                body: 'In a category\'s grid, the "Free draw" button opens '
                    'a board with no target: write any character from that '
                    'category and the app guesses which one it is. A fun '
                    'way to test yourself once you know a few!',
              ),
              const _InstructionSection(
                icon: Icons.repeat,
                title: 'Practice a little, often',
                body: 'A script stays alive as long as hands keep writing '
                    'it. A few characters a day, repeated until they feel '
                    'natural, works better than one long session.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One instruction block: an icon in a rounded square, a title, and a
/// short paragraph. Stacked vertically they form the long how-to page.
class _InstructionSection extends StatelessWidget {
  const _InstructionSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
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
