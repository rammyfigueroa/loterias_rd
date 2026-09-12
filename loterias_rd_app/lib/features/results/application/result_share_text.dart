import '../../../domain/lottery_result.dart';

List<String> resultShareNumbers(LotteryResult result) {
  if (result.prizes.isNotEmpty) {
    return result.prizes.map((prize) => prize.number).toList();
  }
  return result.numbers;
}

String buildResultShareText(LotteryResult result) {
  final numbers = resultShareNumbers(result)
      .map((number) => number.trim())
      .where((number) => number.isNotEmpty)
      .join(' - ');

  final lines = <String>[
    result.lotteryName.trim(),
    if (result.drawName.trim().isNotEmpty) result.drawName.trim(),
    if (numbers.isNotEmpty) 'Resultado: $numbers',
    if (result.drawDate.trim().isNotEmpty) result.drawDate.trim(),
    '',
    'Compartido desde Sorteos Dominicanos',
  ];

  return lines.join('\n');
}
