/// Model representing a lottery result.
class LotteryPrize {
  final int position;
  final String label;
  final String number;

  const LotteryPrize({
    required this.position,
    required this.label,
    required this.number,
  });

  factory LotteryPrize.fromJson(Map<String, dynamic> json) {
    return LotteryPrize(
      position: int.tryParse((json['position'] ?? '').toString()) ?? 0,
      label: (json['label'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'label': label,
      'number': number,
    };
  }
}

class LotteryResult {
  final String lotteryName;
  final String drawName;
  final String drawDate;
  final List<String> numbers;
  final List<LotteryPrize> prizes;
  final bool isVerified;
  final String? prize;

  LotteryResult({
    required this.lotteryName,
    required this.drawName,
    required this.drawDate,
    required this.numbers,
    this.prizes = const [],
    this.isVerified = false,
    this.prize,
  });

  /// Construct from JSON as returned by the backend.
  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    final rawNumbers = json['numbers'];

    final parsedNumbers = rawNumbers is List
        ? rawNumbers.map((e) => e.toString()).toList()
        : <String>[];

    final rawPrizes = json['prizes'];
    final parsedPrizes = rawPrizes is List
        ? rawPrizes
            .whereType<Map>()
            .map((item) =>
                LotteryPrize.fromJson(Map<String, dynamic>.from(item)))
            .where((prize) => prize.number.isNotEmpty)
            .toList()
        : <LotteryPrize>[];

    final rawPrize = json['prize'];

    return LotteryResult(
      lotteryName: (json['lotteryName'] ?? '').toString(),
      drawName: (json['drawName'] ?? '').toString(),
      drawDate: (json['drawDate'] ?? '').toString(),
      numbers: parsedNumbers,
      prizes: parsedPrizes,
      isVerified: json['isVerified'] == true,
      prize: rawPrize == null ? null : rawPrize.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lotteryName': lotteryName,
      'drawName': drawName,
      'drawDate': drawDate,
      'numbers': numbers,
      'prizes': prizes.map((prize) => prize.toJson()).toList(),
      'isVerified': isVerified,
      'prize': prize,
    };
  }
}
