import 'package:flutter/material.dart';

/// Displays the first three prize numbers horizontally with labels beneath.
///
/// The numbers are coloured blue, grey and red to correspond to first,
/// second and third prizes respectively. Beneath each ball a small label
/// (e.g. "1ero", "2do", "3ero") is shown. If fewer than three numbers
/// are supplied, empty placeholders are rendered.
class LabeledResultBalls extends StatelessWidget {
  final List<String> numbers;
  final double size;
  final bool expand;

  const LabeledResultBalls({
    super.key,
    required this.numbers,
    this.size = 40,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final colours = [
      const Color(0xFF003893),
      const Color(0xFFF3F4F6),
      const Color(0xFFD90F2C),
    ];
    final labels = ['1ero', '2do', '3ero'];

    final padded = List<String>.from(numbers);
    while (padded.length < 3) {
      padded.add('');
    }

    final ballWidgets = List.generate(3, (index) {
      final number = padded[index];
      final colour = colours[index];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colour,
              border: Border.all(
                color: index == 1
                    ? Colors.grey.shade300
                    : Colors.white.withOpacity(0.72),
                width: index == 1 ? 2.2 : 2,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  offset: Offset(0, 4),
                  color: Colors.black26,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: index == 1 ? const Color(0xFF111827) : Colors.white,
                fontSize: size * 0.42,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(height: size * 0.12),
          SizedBox(
            width: size,
            child: Text(
              labels[index],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
            ),
          ),
        ],
      );
    });

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment:
            expand ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
        children: expand
            ? ballWidgets
            : [
                for (int i = 0; i < ballWidgets.length; i++) ...[
                  ballWidgets[i],
                  if (i != ballWidgets.length - 1) SizedBox(width: size * 0.32),
                ],
              ],
      ),
    );
  }
}
