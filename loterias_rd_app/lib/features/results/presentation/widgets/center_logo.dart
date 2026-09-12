import 'package:flutter/material.dart';

/// A bingo‑style logo adapted for the Sorteos Dominicanos app.
///
/// This widget draws three coloured balls (blue, white and red) with
/// the numbers 1, 2 and 3 inside, arranged horizontally with a slight
/// overlap. Below the balls, the app name "Sorteos Dominicanos" is rendered in
/// bold red letters with a white outline to mimic the playful style
/// of a bingo logo. The entire logo is centred horizontally. If you
/// need a smaller or larger version of the logo, wrap this widget in
/// a `SizedBox` or `Transform.scale`.
class CenterLogo extends StatelessWidget {
  const CenterLogo({super.key});

  @override
  Widget build(BuildContext context) {
    const double ballSize = 56.0;
    // Horizontal overlap as a fraction of ball size. A value between 0 and 1.
    const double overlapFraction = 0.4;
    final double overlap = ballSize * overlapFraction;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: ballSize * 3 - overlap * 2 + 2, // adjust width for overlap
          height: ballSize * 1.2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Left ball (blue)
              Positioned(
                left: 0,
                top: 0,
                child: _buildBall(ballSize, const Color(0xFF003893), '1'),
              ),
              // Middle ball (white) with border to stand out on light backgrounds
              Positioned(
                left: ballSize - overlap,
                top: ballSize * 0.15,
                child: _buildBall(ballSize, const Color(0xFFF3F4F6), '2', border: true),
              ),
              // Right ball (red)
              Positioned(
                left: 2 * (ballSize - overlap),
                top: 0,
                child: _buildBall(ballSize, const Color(0xFFD90F2C), '3'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Text with white outline and red fill.
        Stack(
          alignment: Alignment.center,
          children: [
            // Outline layer
            Text(
              'Sorteos Dominicanos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = Colors.white,
              ),
            ),
            // Fill layer
            const Text(
              'Sorteos Dominicanos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFFD90F2C),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBall(double size, Color colour, String text, {bool border = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colour,
        border: border
            ? Border.all(color: Colors.grey.shade400, width: 4)
            : null,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 3),
            color: Colors.black26,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
          color: colour == const Color(0xFFF3F4F6) ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}