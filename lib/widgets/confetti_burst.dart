import 'dart:math';

import 'package:flutter/material.dart';

/// A one-shot confetti burst: small colored rectangles spray out from the
/// center, tumble under gravity, and fade — then the widget goes blank.
///
/// Plays once when it's built (the result sheet builds it only on a
/// successful match). Purely decorative: it sits in an IgnorePointer so
/// taps pass straight through to the buttons underneath.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Piece {
  _Piece(Random random)
      // Angles favour "up": between -30° and -150° in screen coordinates
      // (y grows downwards), like confetti popped from a cannon.
      : angle = -pi / 6 - random.nextDouble() * (2 * pi / 3),
        speed = 120 + random.nextDouble() * 240,
        spin = (random.nextDouble() - 0.5) * 12,
        size = 5 + random.nextDouble() * 5,
        color = _colors[random.nextInt(_colors.length)];

  final double angle;
  final double speed; // logical pixels per second at launch
  final double spin; // radians per second of tumbling
  final double size;
  final Color color;

  static const _colors = [
    Color(0xFFE53935), // red
    Color(0xFFFDD835), // yellow
    Color(0xFF43A047), // green
    Color(0xFF1E88E5), // blue
    Color(0xFF8E24AA), // purple
    Color(0xFFFB8C00), // orange
  ];
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _pieceCount = 36;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  // Generated once so the pieces don't reshuffle on every frame.
  final List<_Piece> _pieces =
      List.generate(_pieceCount, (_) => _Piece(Random()));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_pieces, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress);

  final List<_Piece> pieces;

  /// 0 → burst begins, 1 → all faded out.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final origin = Offset(size.width / 2, size.height / 2);
    final t = progress * 1.4; // seconds since launch
    final opacity = 1 - Curves.easeIn.transform(progress);
    final paint = Paint();

    for (final piece in pieces) {
      // Ballistics: launch velocity + gravity pulling the piece down.
      final position = origin +
          Offset(cos(piece.angle), sin(piece.angle)) * piece.speed * t +
          Offset(0, 220 * t * t);

      paint.color = piece.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(piece.spin * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
