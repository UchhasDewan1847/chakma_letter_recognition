import 'package:flutter/material.dart';

import '../models/letter_category.dart';
import '../widgets/app_background.dart';
import 'letter_select_screen.dart';

/// The app's home page: a motivational header plus one card per practice
/// category (consonants, numbers, and a "coming soon" teaser for vowels).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              // ---- Header: logo, app name, motivation ----
              const SizedBox(height: 8),
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
                  subtitle:
                      '${category.letters.length} ${category.itemNoun}s to master',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LetterSelectScreen(category: category),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              // ---- Vowels: model not trained yet ----
              _CategoryCard(
                emblem: '\u{11104}', // i
                title: 'Vowels',
                subtitle: '4 letters — coming soon',
                enabled: false,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('The vowel model is still in training — soon!'),
                    ),
                  );
                },
              ),
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
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final String emblem;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Disabled cards (vowels) fade out but still explain themselves on tap.
    final fade = enabled ? 1.0 : 0.5;

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
                  color: theme.colorScheme.primaryContainer.withOpacity(fade),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  emblem,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color:
                        theme.colorScheme.onPrimaryContainer.withOpacity(fade),
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
                        color: theme.colorScheme.onSurface.withOpacity(fade),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(fade),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                enabled ? Icons.chevron_right : Icons.lock_clock,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(fade),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
