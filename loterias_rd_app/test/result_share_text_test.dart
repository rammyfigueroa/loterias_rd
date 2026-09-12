import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/domain/lottery_result.dart';
import 'package:sorteosdominicanos_app/features/results/application/result_share_text.dart';

void main() {
  test('buildResultShareText includes visible result values', () {
    final result = LotteryResult(
      lotteryName: 'Loteria Nacional',
      drawName: 'Quiniela',
      drawDate: '10 de septiembre de 2026',
      numbers: const ['12', '34', '56'],
    );

    final text = buildResultShareText(result);

    expect(text, contains('Loteria Nacional'));
    expect(text, contains('Quiniela'));
    expect(text, contains('Resultado: 12 - 34 - 56'));
    expect(text, contains('10 de septiembre de 2026'));
    expect(text, contains('Compartido desde Sorteos Dominicanos'));
  });

  test('buildResultShareText prefers prizes over fallback numbers', () {
    final result = LotteryResult(
      lotteryName: 'Leidsa',
      drawName: 'Quiniela Leidsa',
      drawDate: '2026-09-10',
      numbers: const ['99', '88', '77'],
      prizes: const [
        LotteryPrize(position: 1, label: '1ro', number: '01'),
        LotteryPrize(position: 2, label: '2do', number: '02'),
        LotteryPrize(position: 3, label: '3ro', number: '03'),
      ],
    );

    final text = buildResultShareText(result);

    expect(text, contains('Resultado: 01 - 02 - 03'));
    expect(text, isNot(contains('99 - 88 - 77')));
  });

  test('buildResultShareText does not include restricted lottery language', () {
    final result = LotteryResult(
      lotteryName: 'Loto Real',
      drawName: 'Sorteo diario',
      drawDate: '2026-09-10',
      numbers: const ['10', '20', '30'],
    );

    final text = buildResultShareText(result).toLowerCase();

    expect(text, isNot(contains('resultado oficial')));
    expect(text, isNot(contains('resultado verificado')));
    expect(text, isNot(contains('ganador')));
    expect(text, isNot(contains('apuesta')));
    expect(text, isNot(contains('juega aquí')));
  });
}
