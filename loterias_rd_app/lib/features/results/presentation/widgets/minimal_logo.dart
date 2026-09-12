import 'package:flutter/material.dart';

/// A minimalistic logo for the home screen that uses three coloured balls
/// representing the first, second and third prizes. This version is
/// intentionally compact so that it occupies less vertical space than
/// the full centre logo. It does not display any text.
class MinimalLogo extends StatelessWidget {
  final double size;

  const MinimalLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    // Define the colours for the 1st, 2nd and 3rd prize balls.
    const colours = [
      Color(0xFF003893), // dark blue
      Color(0xFFF3F4F6), // light grey (for the second prize)
      Color(0xFFD90F2C), // red
    ];
    final numbers = ['1', '2', '3'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final colour = colours[index];
        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.only(right: index == 2 ? 0 : size * 0.3),
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
            // Apply a subtle halo (border) around each ball to separate it
            // from the background. This emulates the light halo seen on the
            // white ball in the original design.
            border: Border.all(color: Colors.grey.shade400, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            numbers[index],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              // Use black text on the grey (second) ball, white otherwise.
              color: index == 1 ? Colors.black : Colors.white,
              fontSize: size * 0.4,
            ),
          ),
        );
      }),
    );
  }
}