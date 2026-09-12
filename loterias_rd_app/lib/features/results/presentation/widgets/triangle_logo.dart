import 'package:flutter/material.dart';

/// A lightweight widget that draws three balls in a triangular formation.
///
/// The balls are coloured blue, white and red, numbered 1, 2 and 3 and
/// represent the first, second and third prizes. This can be used in
/// the app bar as a logo instead of importing a bitmap image.
class TriangleLogo extends StatelessWidget {
  const TriangleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    // Size of each ball in the logo.
    const double size = 28;
    // We enlarge the container to create more space between the balls
    // so they are more clearly separated. The width is set to three
    // times the ball size and the height slightly larger than twice
    // the size to maintain the triangular appearance.
    final double width = size * 3;
    final double height = size * 2.5;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top ball (first prize) positioned in the middle of the width.
          Positioned(
            top: 0,
            left: (width - size) / 2,
            child: _buildBall(size, Colors.blue, '1'),
          ),
          // Bottom-left (second prize) anchored to the bottom-left corner.
          Positioned(
            bottom: 0,
            left: 0,
            child: _buildBall(size, Colors.white, '2'),
          ),
          // Bottom-right (third prize) anchored to the bottom-right corner.
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildBall(size, Colors.red, '3'),
          ),
        ],
      ),
    );
  }

  Widget _buildBall(double size, Color colour, String text) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colour,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 2),
            color: Colors.black26,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: colour == Colors.white ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}