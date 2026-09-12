import 'package:flutter/material.dart';

/// A simple circle avatar representing a lottery using the first letter of
/// its name. The background colour is chosen deterministically based on
/// the lottery name to help visually differentiate different lotteries.
class LotteryLogo extends StatelessWidget {
  final String lotteryName;

  const LotteryLogo({super.key, required this.lotteryName});

  @override
  Widget build(BuildContext context) {
    final letter =
        lotteryName.isNotEmpty ? lotteryName[0].toUpperCase() : '?';
    // Generate a colour deterministically from the hash code. A small set
    // of colours is used to keep the palette cohesive.
    final colours = [
      Colors.blue.shade800,
      Colors.red.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
    ];
    final index = lotteryName.hashCode.abs() % colours.length;
    final backgroundColour = colours[index];
    return CircleAvatar(
      radius: 20,
      backgroundColor: backgroundColour,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}