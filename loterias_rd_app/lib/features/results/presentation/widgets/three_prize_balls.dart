import 'dart:math' as math;

import 'package:flutter/material.dart';

class ThreePrizeBalls extends StatelessWidget {
  final List<String> numbers;
  final List<String>? labels;
  final double maxSize;
  final Color? labelColor;

  const ThreePrizeBalls({
    super.key,
    required this.numbers,
    this.labels,
    this.maxSize = 84,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final visibleNumbers = List<String>.from(numbers.take(3));
    final defaultLabels = ['1ro', '2do', '3ro'];
    final visibleLabels = List<String>.generate(visibleNumbers.length, (index) {
      final customLabel =
          labels != null && index < labels!.length ? labels![index].trim() : '';
      return customLabel.isNotEmpty ? customLabel : defaultLabels[index];
    });
    final colors = [
      const Color(0xFF003893),
      const Color(0xFFF8FAFC),
      const Color(0xFFD90F2C),
    ];
    final textColors = [
      Colors.white,
      const Color(0xFF0F172A),
      Colors.white,
    ];
    final borderColors = <Color?>[
      null,
      const Color(0xFFE2E8F0),
      null,
    ];

    if (visibleNumbers.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 48;
        final count = visibleNumbers.length;
        final size = count == 1
            ? math.min(maxSize, availableWidth * 0.36).clamp(72.0, maxSize)
            : math.min(maxSize, (availableWidth - 56) / 3).clamp(58.0, maxSize);

        return Row(
          mainAxisAlignment: count == 1
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: List.generate(count, (index) {
            return _PrizeColumn(
              number: visibleNumbers[index],
              label: visibleLabels[index],
              size: size,
              color: colors[index],
              textColor: textColors[index],
              borderColor: borderColors[index],
              labelColor: labelColor,
            );
          }),
        );
      },
    );
  }
}

class _PrizeColumn extends StatelessWidget {
  final String number;
  final String label;
  final double size;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final Color? labelColor;

  const _PrizeColumn({
    required this.number,
    required this.label,
    required this.size,
    required this.color,
    required this.textColor,
    this.borderColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrizeBall(
          number: number,
          size: size,
          color: color,
          textColor: textColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: labelColor ?? Colors.grey.shade600,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _PrizeBall extends StatelessWidget {
  final String number;
  final double size;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  const _PrizeBall({
    required this.number,
    required this.size,
    required this.color,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border:
            Border.all(color: borderColor ?? const Color(0xFFD9E1EC), width: 3),
        boxShadow: const [
          BoxShadow(
            blurRadius: 9,
            offset: Offset(0, 4),
            color: Colors.black26,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        maxLines: 1,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
