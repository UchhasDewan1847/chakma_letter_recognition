import 'package:flutter/material.dart';

import '../models/letter_category.dart';
import '../services/progress_store.dart';
import '../widgets/app_background.dart';
import 'instructions_screen.dart';
import 'letter_select_screen.dart';

/// The app's home page: a motivational header plus one card per practice
/// category (consonants, numbers, vowels).
///
/// Stateful because each card shows how many characters are mastered
/// (see [ProgressStore]); the counts are loaded on open and again after
/// every visit to a category, so progress is always current.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Mastered-character count per category title (empty until loaded).
  Map<String, int> _masteredCounts = const {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final counts = <String, int>{
      for (final category in practiceCategories)
        category.title:
            (await ProgressStore.masteredGlyphs(category.letters)).length,
    };
    if (!mounted) return;
    setState(() => _masteredCounts = counts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        // Transparent so the blurred illustration shows through.
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ---- The "paper" button: opens the how-to page any time ----
              // (The onboarding slides only appear on the very first launch,
              // so this is the permanent home of the instructions.)
              Align(
                alignment: Alignment.topRight,
                child: IconButton.filledTonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InstructionsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined),
                  tooltip: 'How to use',
                ),
              ),
              // ---- Header: logo, app name, motivation ----
              Center(
                child: Image.asset(
                  'assets/images/logo/logo-1rst.png',
                  height: 110,
                  // Keeps the app alive if the logo file ever goes missing.
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.draw_outlined,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ojha Paath Sigi',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A script stays alive as long as hands keep writing it.\n'
                'Let’s learn to write Chakma — one stroke at a time.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'What do you want to practice?',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // ---- One tappable card per ready category ----
              for (final category in practiceCategories) ...[
                _CategoryCard(
                  emblem: category.emblemGlyph,
                  title: category.title,
                  masteredCount: _masteredCounts[category.title] ?? 0,
                  totalCount: category.letters.length,
                  itemNoun: category.itemNoun,
                  onTap: () async {
                    // Wait for the category to close, then re-read progress
                    // — stars may have been earned while practicing.
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LetterSelectScreen(category: category),
                      ),
                    );
                    _loadProgress();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emblem,
    required this.title,
    required this.masteredCount,
    required this.totalCount,
    required this.itemNoun,
    required this.onTap,
  });

  final String emblem;
  final String title;
  final int masteredCount;
  final int totalCount;
  final String itemNoun;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final started = masteredCount > 0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  emblem,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      started
                          ? '$masteredCount of $totalCount ${itemNoun}s mastered'
                          : '$totalCount ${itemNoun}s to master',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalCount == 0
                            ? 0
                            : masteredCount / totalCount,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
