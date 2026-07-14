import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/chakma_letter.dart';
import '../models/letter_category.dart';
import '../services/class_label_map.dart';
import '../services/letter_recognizer.dart';
import '../widgets/app_background.dart';
import '../widgets/drawing_board.dart';

/// Where the user practices writing one character.
///
/// Layout: the target letter on top, the drawing board in the middle,
/// and Clear / Undo / Check buttons at the bottom.
///
/// When Check is tapped we snapshot the board through its RepaintBoundary,
/// hand the image to [LetterRecognizer], and show the result in a
/// bottom sheet.
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
    final isMatch =
        predictedName?.toLowerCase() == widget.letter.name.toLowerCase();

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
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
              isMatch ? 'Great job!' : 'Not quite — try again!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The model read your writing as:',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(displayLabel(best.label))),
                Text(
                  '${(best.probability * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
                // The letter the user should copy.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Try to write this ${widget.category.itemNoun}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        widget.letter.glyph,
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 96,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // The drawing area. AspectRatio keeps it square, matching the
                // square 224x224 input the model expects.
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DrawingBoard(
                        controller: _controller,
                        repaintKey: _boardKey,
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
