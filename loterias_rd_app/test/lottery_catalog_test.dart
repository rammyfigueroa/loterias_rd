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

    test('detects today using the Dominican Republic calendar date', () {
      final group = LotteryGroup(
        id: 'anguila',
        name: 'Anguila',
        results: [
          result(
            lottery: 'Anguila',
            draw: 'Noche',
            date: '2026-10-21',
          ),
        ],
      );

      expect(
        lotteryHasResultsToday(
          group,
          nowUtc: DateTime.utc(2026, 10, 22, 3, 59),
        ),
        isTrue,
      );
      expect(
        lotteryHasResultsToday(
          group,
          nowUtc: DateTime.utc(2026, 10, 22, 4, 1),
        ),
        isFalse,
      );
    });

    test('does not mark previous or invalid draw dates as today', () {
      final nowUtc = DateTime.utc(2026, 10, 21, 18);
      expect(
        isResultFromDominicanToday(
          result(lottery: 'Real', draw: 'Tarde', date: '2026-10-20'),
          nowUtc: nowUtc,
        ),
        isFalse,
      );
      expect(
        isResultFromDominicanToday(
          result(lottery: 'Real', draw: 'Tarde', date: 'sin-fecha'),
          nowUtc: nowUtc,
        ),
        isFalse,
      );
    });

    test('calculates the next Dominican day without a polling timer', () {
      expect(
        untilNextDominicanDay(DateTime.utc(2026, 10, 21, 15, 30)),
        const Duration(hours: 12, minutes: 30),
      );
    });

    test('short visible groups use the larger responsive size only', () {
      for (var count = 1; count <= 3; count++) {
        final item = result(
          lottery: 'Anguila',
          draw: 'Tarde',
          date: '2026-10-21',
          numbers: List.generate(count, (index) => '$index'),
        );
        expect(hasShortVisibleNumberGroup(item), isTrue);
        expect(
          responsiveShortGroupBallSize(
            result: item,
            availableWidth: 500,
            spacing: 9,
            standardSize: 39,
            maximumShortSize: 50,
          ),
          50,
        );
      }

      for (final count in [4, 5]) {
        final item = result(
          lottery: 'Nacional',
          draw: 'Loto',
          date: '2026-10-21',
          numbers: List.generate(count, (index) => '$index'),
        );
        expect(hasShortVisibleNumberGroup(item), isFalse);
        expect(
          responsiveShortGroupBallSize(
            result: item,
            availableWidth: 500,
            spacing: 7,
            standardSize: 39,
            maximumShortSize: 50,
          ),
          39,
        );
      }

      final individualShort = result(
        lottery: 'Anguila',
        draw: 'Noche',
        date: '2026-10-21',
        numbers: const ['27', '22', '80'],
      );
      expect(
        responsiveShortGroupBallSize(
          result: individualShort,
          availableWidth: 320,
          spacing: 12,
          standardSize: 64,
          maximumShortSize: 92,
        ),
        92,
      );
    });
  });
}
