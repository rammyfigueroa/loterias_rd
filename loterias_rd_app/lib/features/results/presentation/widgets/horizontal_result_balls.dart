import 'dart:math' as math;

import 'package:flutter/material.dart';

class HorizontalResultBalls extends StatelessWidget {
  final List<String> numbers;
  final double size;
  final int maxPerRow;

  const HorizontalResultBalls({
    super.key,
    required this.numbers,
    this.size = 58,
    this.maxPerRow = 5,
  });

  @override
  Widget build(BuildContext context) {
    final displayNumbers = numbers
        .where((value) => !RegExp(r'^\d+x$', caseSensitive: false).hasMatch(value.trim()))
        .toList();

    if (displayNumbers.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = _rowsFor(displayNumbers, maxPerRow);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 48;
        final rowCount = rows.fold<int>(0, (max, row) => math.max(max, row.length));
        final targetSize = _targetSize(displayNumbers.length, size);
        final gap = _gapFor(displayNumbers.length);
        final fittedSize = rowCount <= 1
            ? targetSize
            : math.min(targetSize, (width - gap * (rowCount - 1)) / rowCount);
        final ballSize = fittedSize.clamp(38.0, targetSize).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: rows.map((row) {
            return Padding(
              padding: EdgeInsets.only(bottom: row == rows.last ? 0 : 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.asMap().entries.map((entry) {
                  final isLast = entry.key == row.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : gap),
                    child: _ResultBall(
                      value: entry.value,
                      size: ballSize,
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<List<String>> _rowsFor(List<String> values, int maxPerRow) {
    final rows = <List<String>>[];
    for (var i = 0; i < values.length; i += maxPerRow) {
      rows.add(values.skip(i).take(maxPerRow).toList());
    }
    return rows;
  }

  double _targetSize(int count, double baseSize) {
    if (count <= 3) return baseSize;
    if (count == 4) return math.min(baseSize, 56);
    if (count == 5) return math.min(baseSize, 50);
    if (count <= 10) return math.min(baseSize, 46);
    return math.min(baseSize, 42);
  }

  double _gapFor(int count) {
    if (count <= 4) return 18;
    if (count == 5) return 14;
    return 12;
  }
}

class _ResultBall extends StatelessWidget {
  final String value;
  final double size;

  const _ResultBall({
    required this.value,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFD9E1EC), width: 1.6),
          boxShadow: const [
            BoxShadow(
              blurRadius: 7,
              offset: Offset(0, 4),
              color: Colors.black26,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: const Color(0xFF003893),
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
