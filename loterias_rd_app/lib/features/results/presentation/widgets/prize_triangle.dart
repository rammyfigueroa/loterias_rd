import 'package:flutter/material.dart';

/// Displays three prize numbers in a triangular arrangement.
///
/// The first prize (index 0) appears at the top, second (index 1) bottom-left,
/// and third (index 2) bottom-right. The balls are coloured blue, white and
/// red respectively and sized to stand out in the card layout. A subtle
/// border is added to the white ball so it does not blend into a white
/// background.
class PrizeTriangle extends StatelessWidget {
  final List<String> numbers;
  final double size;

  const PrizeTriangle({super.key, required this.numbers, this.size = 48});

  @override
  Widget build(BuildContext context) {
    // Ensure we always have three entries; pad with empty strings.
    final padded = List<String>.from(numbers);
    while (padded.length < 3) {
      padded.add('');
    }
    final colours = [Colors.blue, Colors.white, Colors.red];
    return SizedBox(
      width: size * 2,
      height: size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top ball (first prize)
          Positioned(
            top: 0,
            left: size / 2,
            child: _buildBall(size, colours[0], padded[0]),
          ),
          // Bottom-left (second prize)
          Positioned(
            bottom: 0,
            left: 0,
            child: _buildBall(size, colours[1], padded[1]),
          ),
          // Bottom-right (third prize)
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildBall(size, colours[2], padded[2]),
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
        border: colour == Colors.white
            ? Border.all(color: Colors.blueGrey, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: colour == Colors.white ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}