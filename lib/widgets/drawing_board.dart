import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// A single continuous pen stroke: the points the finger passed through.
typedef Stroke = List<Offset>;

/// Holds the strokes drawn so far and notifies listeners when they change.
///
/// Kept separate from the widget so the practice screen can own the state
/// (for the Clear/Undo buttons) while the board only handles touch input.
class DrawingController extends ChangeNotifier {
  final List<Stroke> strokes = [];

  bool get isEmpty => strokes.isEmpty;

  void startStroke(Offset point) {
    strokes.add([point]);
    notifyListeners();
  }

  void extendStroke(Offset point) {
    if (strokes.isEmpty) return;
    strokes.last.add(point);
    notifyListeners();
  }

  void undo() {
    if (strokes.isEmpty) return;
    strokes.removeLast();
    notifyListeners();
  }

  void clear() {
    strokes.clear();
    notifyListeners();
  }
}

/// The square canvas the user writes on.
///
/// Wrapped in a [RepaintBoundary] with [repaintKey] so that later we can
/// capture the drawing as an image and feed it to the ONNX model.
class DrawingBoard extends StatelessWidget {
  const DrawingBoard({
    super.key,
    required this.controller,
    this.repaintKey,
  });

  final DrawingController controller;
  final GlobalKey? repaintKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onPanStart: (details) => controller.startStroke(details.localPosition),
          onPanUpdate: (details) => controller.extendStroke(details.localPosition),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => CustomPaint(
              painter: _StrokePainter(controller.strokes),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes);

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        // A tap without movement: draw a dot.
        canvas.drawPoints(PointMode.points, stroke, paint);
      } else {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (final point in stroke.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) => true;
}
