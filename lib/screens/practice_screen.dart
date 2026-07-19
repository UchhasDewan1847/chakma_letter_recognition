import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../models/chakma_letter.dart';
import '../models/letter_category.dart';
import '../services/class_label_map.dart';
import '../services/letter_recognizer.dart';
import '../services/progress_store.dart';
import '../widgets/app_background.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/drawing_board.dart';

/// Three difficulty levels for practicing one character.
enum PracticeMode {
  /// A faint copy of the character sits on the board to draw over.
  trace('Trace'),

  /// The sample stays visible up top; the board is blank.
  copy('Copy'),

  /// The sample is hidden — write from memory (hold the card to peek).
  memory('Memory');

  const PracticeMode(this.label);
  final String label;
}

/// Where the user practices writing one character.
///
/// Layout: the target letter on top, a Trace/Copy/Memory mode picker,
/// the drawing board in the middle, and Clear / Undo / Check buttons at
/// the bottom.
///
/// When Check is tapped we snapshot the board through its RepaintBoundary,
/// hand the image to [LetterRecognizer], and show the result in a
/// bottom sheet. Every check is recorded in [ProgressStore] so the grid
/// and home screen can show mastery.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.letter,
    required this.category,
  });

  final ChakmaLetter letter;

  /// Decides which ONNX model judges the drawing.
  final LetterCategory category;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _controller = DrawingController();
  final _boardKey = GlobalKey();
  // Set in initState because field initializers run before `widget` exists.
  late final LetterRecognizer _recognizer;
  bool _checking = false;
  PracticeMode _mode = PracticeMode.trace;
  // True while the user holds the target card in Memory mode to peek.
  bool _peeking = false;

  @override
  void initState() {
    super.initState();
    _recognizer = LetterRecognizer(
      modelAsset: widget.category.modelAsset,
      labelsAsset: widget.category.labelsAsset,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _recognizer.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _check() async {
    if (_controller.isEmpty) {
      _showMessage('Draw the ${widget.category.itemNoun} first!');
      return;
    }
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final error = await _recognizer.load();
      if (!mounted) return;
      if (error != null) {
        _showMessage(error);
        return;
      }

      // Snapshot the drawing board as an image.
      final boundary =
          _boardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage();

      final predictions = await _recognizer.recognize(image);
      image.dispose();
      if (!mounted) return;
      _showResult(predictions);
    } catch (e) {
      _showMessage('Something went wrong while checking: $e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showResult(List<Prediction> predictions) {
    final best = predictions.first;
    // The model outputs raw dataset labels ("1-𑄇" or "𑄶"); only a mapped
    // label can count as a correct match.
    final predictedName = letterNameForLabel(best.label);
    final targetName = widget.letter.name.toLowerCase();
    final isMatch = predictedName?.toLowerCase() == targetName;

    // Count this attempt towards mastery (fire-and-forget disk write),
    // and give a small buzz on success so the win is felt, not just seen.
    ProgressStore.recordAttempt(widget.letter.glyph, matched: isMatch);
    if (isMatch) {
      HapticFeedback.mediumImpact();
    }

    // Turn the model's numbers into human words. Raw confidence ("89.2%")
    // means little to a learner, so instead the phrasing is graded on how
    // sure the model is, and — on a miss — on whether the right character
    // at least appears among its top guesses.
    final String headline;
    final String detail;
    if (isMatch) {
      if (best.probability >= 0.75) {
        headline = 'Great job!';
        detail = 'That clearly matches "${widget.letter.name}". '
            'Beautiful writing!';
      } else {
        headline = 'Good job — it matches!';
        detail = 'The app recognised your "${widget.letter.name}". '
            'A little more practice and it will be unmistakable.';
      }
    } else {
      final almostThere = predictions
          .any((p) => letterNameForLabel(p.label)?.toLowerCase() == targetName);
      if (almostThere) {
        headline = 'So close!';
        detail = 'It almost matches, but it looks a bit more like another '
            'character. Compare with the sample and try once more.';
      } else {
        headline = 'Not close enough yet';
        detail = 'Sorry, the app couldn\'t recognise it as '
            '"${widget.letter.name}". Look at the sample\'s shape again — '
            'you\'ll get it!';
      }
    }

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Stack(
        children: [
          // The celebration layer: only exists on a match, plays once,
          // and ignores taps so the button stays pressable through it.
          if (isMatch) const Positioned.fill(child: ConfettiBurst()),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  isMatch ? Icons.celebration : Icons.refresh,
                  size: 56,
                  color: isMatch ? Colors.green : theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  headline,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                if (!isMatch) ...[
                  const SizedBox(height: 12),
                  Text(
                    'The app read it as ${displayLabel(best.label)}',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isMatch) {
                      _controller.clear();
                    }
                  },
                  child: Text(isMatch ? 'Practice again' : 'Keep trying'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        // Transparent so the blurred illustration shows through.
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Write "${widget.letter.name}"'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // The letter the user should copy. In Memory mode the glyph
                // hides behind a "?" until the card is held down (peek).
                GestureDetector(
                  onTapDown: _mode == PracticeMode.memory
                      ? (_) => setState(() => _peeking = true)
                      : null,
                  onTapUp: (_) => setState(() => _peeking = false),
                  onTapCancel: () => setState(() => _peeking = false),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _mode == PracticeMode.memory
                              ? 'From memory! Hold this card to peek'
                              : 'Try to write this ${widget.category.itemNoun}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          _mode == PracticeMode.memory && !_peeking
                              ? '?'
                              : widget.letter.glyph,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 96,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Difficulty ladder: trace over a guide, copy the sample,
                // then write from memory.
                SegmentedButton<PracticeMode>(
                  segments: [
                    for (final mode in PracticeMode.values)
                      ButtonSegment(value: mode, label: Text(mode.label)),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => setState(() {
                    _mode = selection.first;
                    _peeking = false;
                  }),
                ),
                const SizedBox(height: 12),
                // The drawing area. AspectRatio keeps it square, matching the
                // square 224x224 input the model expects.
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DrawingBoard(
                            controller: _controller,
                            repaintKey: _boardKey,
                          ),
                          // The trace guide is layered on top of the board but
                          // OUTSIDE its RepaintBoundary, so the snapshot the
                          // model sees stays clean white + strokes. It also
                          // ignores touches, so drawing works right through it.
                          if (_mode == PracticeMode.trace)
                            IgnorePointer(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: FittedBox(
                                  child: Text(
                                    widget.letter.glyph,
                                    style: TextStyle(
                                      fontSize: 200,
                                      color: Colors.grey.withOpacity(0.30),
                                      fontFamilyFallback: const [
                                        'NotoSansChakma'
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: () => _controller.undo(),
                      icon: const Icon(Icons.undo),
                      tooltip: 'Undo last stroke',
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: () => _controller.clear(),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Clear the board',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _checking ? null : _check,
                        icon: _checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label:
                            Text(_checking ? 'Checking…' : 'Check my writing'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
