import 'package:flutter/material.dart';

import '../models/letter_category.dart';
import '../widgets/app_background.dart';
import 'free_draw_screen.dart';
import 'practice_screen.dart';

/// The character grid for one practice category (consonants or numbers).
class LetterSelectScreen extends StatelessWidget {
  const LetterSelectScreen({super.key, required this.category});

  final LetterCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letters = category.letters;

    return AppBackground(
      child: Scaffold(
        // Transparent so the blurred illustration shows through.
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Choose a ${category.itemNoun}'),
          centerTitle: true,
        ),
        // floatingActionButton lives on the Scaffold (not in the body) so it
        // floats above the grid and stays put while the grid scrolls.
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FreeDrawScreen(category: category),
              ),
            );
          },
          icon: const Icon(Icons.gesture),
          label: const Text('Free draw'),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: letters.length,
          itemBuilder: (context, index) {
            final letter = letters[index];
            return Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PracticeScreen(
                        letter: letter,
                        category: category,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      letter.glyph,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      letter.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
