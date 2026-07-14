import 'package:flutter/material.dart';

/// Paints the blurred village illustration behind a screen's content.
///
/// The picture is blurred ahead of time (assets/images/background_blurred.jpg,
/// generated from potentialBackGround3.jpg) rather than with a live
/// BackdropFilter, which would re-blur on the GPU every frame. A translucent
/// wash of the theme's surface colour goes on top so text and cards stay
/// readable over the picture.
///
/// Screens wrap their Scaffold in this and set the Scaffold (and AppBar)
/// backgroundColor to transparent so the picture shows through.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/background_blurred.jpg',
          fit: BoxFit.cover,
          // Plain surface colour if the file is missing — never crash.
          errorBuilder: (_, __, ___) => ColoredBox(color: surface),
        ),
        ColoredBox(color: surface.withOpacity(0.72)),
        child,
      ],
    );
  }
}
