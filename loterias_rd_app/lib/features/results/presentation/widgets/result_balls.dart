import 'package:flutter/material.dart';

/// Widget that renders the three main prize numbers as coloured balls.
///
/// The first, second and third numbers are coloured blue, white and red
/// respectively. If fewer than three numbers are provided, empty
/// placeholders are shown.
class ResultBalls extends StatelessWidget {
  final List<String> numbers;
  final double size;

  /// Displays three balls horizontally with colours blue, white and red.
  /// The optional [size] parameter controls the diameter of each ball.
  const ResultBalls({super.key, required this.numbers, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final colours = [Colors.blue, Colors.white, Colors.red];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final number = (index < numbers.length) ? numbers[index] : '';
        final colour = colours[index];
        return Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 6),
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
            number,
            style: TextStyle(
              color: colour == Colors.white ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4,
            ),
          ),
        );
      }),
    );
  }
}