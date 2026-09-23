import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/domain/lottery_result.dart';
import 'package:sorteosdominicanos_app/features/results/application/lottery_catalog.dart';

LotteryResult result({
  required String lottery,
  required String draw,
  required String date,
  List<String> numbers = const ['01', '02', '03'],
}) {
  return LotteryResult(
    lotteryName: lottery,
    drawName: draw,
    drawDate: date,
    numbers: numbers,
  );
}

void main() {
  group('lottery catalog', () {
    test('groups normalized lottery names and sorts their draws', () {
      final groups = groupResultsByLottery([
        result(lottery: 'Lotería Nacional', draw: 'Noche', date: '2026-09-22'),
        result(
            lottery: ' loteria   nacional ', draw: 'Tarde', date: '2026-09-23'),
        result(lottery: 'Leidsa', draw: 'Loto', date: '2026-09-23'),
      ]);

      expect(groups, hasLength(2));
      final nacional = groups.firstWhere((g) => g.id == 'loteria nacional');
      expect(nacional.results, hasLength(2));
      expect(nacional.results.first.drawName, 'Tarde');
    });

    test('searches by lottery, draw, date, and number', () {
      final item = result(
        lottery: 'Lotería Nacional',
        draw: 'Gana Más',
        date: '2026-09-23',
        numbers: ['04', '29', '81'],
      );

      expect(resultMatchesQuery(item, 'nacional'), isTrue);
      expect(resultMatchesQuery(item, 'gana mas'), isTrue);
      expect(resultMatchesQuery(item, '2026-09-23'), isTrue);
      expect(resultMatchesQuery(item, '81'), isTrue);
      expect(resultMatchesQuery(item, 'leidsa'), isFalse);
    });

    test('uses prize numbers when the API provides prizes', () {
      final item = LotteryResult(
        lotteryName: 'Real',
        drawName: 'Super Palé',
        drawDate: '2026-09-23',
        numbers: const ['00'],
        prizes: const [
          LotteryPrize(position: 1, label: 'Primera', number: '74'),
          LotteryPrize(position: 2, label: 'Segunda', number: '39'),
        ],
      );

      expect(resultNumbers(item), ['74', '39']);
      expect(resultMatchesQuery(item, '74'), isTrue);
    });

    test('orders same-day results using the time in the draw name', () {
      final sorted = sortResultsNewestFirst([
        result(lottery: 'Anguila', draw: 'Anguila 2:00 PM', date: '2026-09-23'),
        result(lottery: 'Anguila', draw: 'Anguila 6:00 PM', date: '2026-09-23'),
      ]);

      expect(sorted.first.drawName, contains('6:00 PM'));
    });

    test('returns an empty catalog for empty results', () {
      expect(groupResultsByLottery(const []), isEmpty);
      expect(searchResults(const [], '01'), isEmpty);
    });
  });
}
