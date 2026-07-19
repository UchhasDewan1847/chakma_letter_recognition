import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/letter_category.dart';
import '../services/class_label_map.dart';
import '../services/letter_recognizer.dart';
import '../widgets/app_background.dart';
import '../widgets/drawing_board.dart';

/// A blank board with no target character: write anything and the
/// category's model shows which class it thinks the drawing is closest to.
///
/// This is also handy for checking the dataset-label -> letter mapping:
/// write a character you know and see which class fires.
class FreeDrawScreen extends StatefulWidget {
  const FreeDrawScreen({super.key, required this.category});

  /// Decides which ONNX model judges the drawing.
  final LetterCategory category;

  @override
  State<FreeDrawScreen> createState() => _FreeDrawScreenState();
}

class _FreeDrawScreenState extends State<FreeDrawScreen> {
  final _controller = DrawingController();
  final _boardKey = GlobalKey();
  // Set in initState because field initializers run before `widget` exists.
  late final LetterRecognizer _recognizer;
  bool _predicting = false;
  List<Prediction> _predictions = const [];

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

  Future<void> _predict() async {
    if (_controller.isEmpty) {
      _showMessage('Write something first!');
      return;
    }
    if (_predicting) return;
    setState(() => _predicting = true);

    try {
      final error = await _recognizer.load();
      if (!mounted) return;
      if (error != null) {
        _showMessage(error);
        return;
      }

      final boundary =
          _boardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage();

      final predictions = await _recognizer.recognize(image);
      image.dispose();
      if (!mounted) return;
      setState(() => _predictions = predictions);
    } catch (e) {
      _showMessage('Something went wrong while predicting: $e');
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  void _clear() {
    _controller.clear();
    setState(() => _predictions = const []);
  }

  /// A human word for the model's confidence — friendlier than "89.2%".
  static String _confidenceWords(double probability) {
    if (probability >= 0.75) return 'and it\'s quite sure';
    if (probability >= 0.4) return 'but it\'s not fully sure';
    return 'but it\'s only guessing';
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
          // Says which model is judging, e.g. "Free drawing · Numbers".
          title: Text('Free drawing · ${widget.category.title}'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                // Results stay visible under the board so the user can keep
                // tweaking their drawing and re-predicting.
                if (_predictions.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Closest match',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayLabel(_predictions.first.label),
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              _confidenceWords(
                                  _predictions.first.probability),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: () => _controller.undo(),
                      icon: const Icon(Icons.undo),
                      tooltip: 'Undo last stroke',
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _clear,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Clear the board',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _predicting ? null : _predict,
                        icon: _predicting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                            _predicting ? 'Predicting…' : 'What did I write?'),
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
