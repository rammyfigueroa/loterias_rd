import '../../../domain/lottery_result.dart';
import 'lottery_catalog.dart';

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
  final prizes = result.prizes
      .where((prize) =>
          prize.label.trim().isNotEmpty && prize.number.trim().isNotEmpty)
      .map((prize) => '${prize.label.trim()}: ${prize.number.trim()}')
      .join(' · ');

  final lines = <String>[
    result.lotteryName.trim(),
    if (result.drawName.trim().isNotEmpty) result.drawName.trim(),
    if (numbers.isNotEmpty) 'Resultado: $numbers',
    if (prizes.isNotEmpty) 'Premios: $prizes',
    if (result.drawDate.trim().isNotEmpty)
      formatDrawDateDayFirst(result.drawDate),
    '',
    'Compartido desde Sorteos Dominicanos',
  ];

  return lines.join('\n');
}
