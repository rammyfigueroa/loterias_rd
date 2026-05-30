class LotteryResult {
  const LotteryResult({
    required this.lotteryName,
    required this.drawName,
    required this.drawDate,
    required this.numbers,
    this.prize,
    this.isVerified = false,
  });

  final String lotteryName;
  final String drawName;
  final String drawDate;
  final List<String> numbers;
  final String? prize;
  final bool isVerified;

  bool get hasNumbers => numbers.isNotEmpty;

  String get favoriteKey => '$lotteryName|$drawName';

  String get shareText {
    final buffer = StringBuffer()
      ..writeln('Resultado de $drawName')
      ..writeln('Loteria: $lotteryName')
      ..writeln('Fecha: $drawDate')
      ..writeln('Numeros: ${numbers.join(' - ')}');

    if (prize != null) {
      buffer.writeln('Premio acumulado: $prize');
    }

    buffer.writeln('Resultados informativos. Verifica siempre con la loteria oficial.');
    return buffer.toString();
  }

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    return LotteryResult(
      lotteryName: json['lotteryName'] as String? ?? 'Loteria',
      drawName: json['drawName'] as String? ?? 'Sorteo',
      drawDate: json['drawDate'] as String? ?? 'Hoy',
      numbers: (json['numbers'] as List<dynamic>? ?? const [])
          .map((number) => number.toString())
          .toList(growable: false),
      prize: json['prize'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  LotteryResult copyWith({
    String? lotteryName,
    String? drawName,
    String? drawDate,
    List<String>? numbers,
    String? prize,
    bool? isVerified,
  }) {
    return LotteryResult(
      lotteryName: lotteryName ?? this.lotteryName,
      drawName: drawName ?? this.drawName,
      drawDate: drawDate ?? this.drawDate,
      numbers: numbers ?? this.numbers,
      prize: prize ?? this.prize,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
