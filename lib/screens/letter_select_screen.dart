import 'package:flutter/material.dart';

import '../models/letter_category.dart';
import '../services/progress_store.dart';
import '../widgets/app_background.dart';
import 'free_draw_screen.dart';
import 'practice_screen.dart';

/// The character grid for one practice category (consonants or numbers).
///
/// Stateful because each tile shows a star once its character is mastered
/// (see [ProgressStore]); the set is loaded on open and again after every
/// practice session, so a fresh star appears the moment you come back.
class LetterSelectScreen extends StatefulWidget {
  const LetterSelectScreen({super.key, required this.category});

  final LetterCategory category;

  @override
  State<LetterSelectScreen> createState() => _LetterSelectScreenState();
}

class _LetterSelectScreenState extends State<LetterSelectScreen> {
  Set<String> _masteredGlyphs = const {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final mastered =
        await ProgressStore.masteredGlyphs(widget.category.letters);
    if (!mounted) return;
    setState(() => _masteredGlyphs = mastered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letters = widget.category.letters;

    return AppBackground(
      child: Scaffold(
        // Transparent so the blurred illustration shows through.
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Choose a ${widget.category.itemNoun}'),
          centerTitle: true,
        ),
        // floatingActionButton lives on the Scaffold (not in the body) so it
        // floats above the grid and stays put while the grid scrolls.
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FreeDrawScreen(category: widget.category),
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
            final isMastered = _masteredGlyphs.contains(letter.glyph);
            return Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  // Wait for the practice screen to close, then re-read
                  // progress — the session may have just earned a star.
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PracticeScreen(
                        letter: letter,
                        category: widget.category,
                      ),
                    ),
                  );
                  _loadProgress();
                },
                child: Stack(
                  children: [
                    if (isMastered)
                      Positioned(
                        top: 6,
                        right: 8,
                        child: Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: Colors.amber.shade600,
                        ),
                      ),
                    Center(
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
