import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sorteosdominicanos_app/features/first_prize_statistics/application/first_prize_statistics_controller.dart';
import 'package:sorteosdominicanos_app/features/first_prize_statistics/data/first_prize_statistics_config.dart';
import 'package:sorteosdominicanos_app/features/first_prize_statistics/data/first_prize_statistics_remote_source.dart';
import 'package:sorteosdominicanos_app/features/first_prize_statistics/data/first_prize_statistics_repository.dart';
import 'package:sorteosdominicanos_app/features/first_prize_statistics/domain/first_prize_statistics.dart';
import 'package:sorteosdominicanos_app/features/first_prize_statistics/presentation/first_prize_statistics_page.dart';

const qualityJson = {
  'firstAvailableDate': '2026-04-29',
  'lastAvailableDate': '2026-10-28',
  'resultsAnalyzed': 181,
  'verifiedIntervals': 49,
  'incompleteCoverageIntervals': 43,
  'unverifiedDates': [
    {'date': '2026-08-16', 'status': 'UNVERIFIED'}
  ],
};

Map<String, dynamic> numberJson(String number,
        {String status = 'MULTIPLE_APPEARANCES', int? days = 5}) =>
    {
      'number': number,
      'sampleStatus': status,
      'appearancesObserved': status == 'NO_APPEARANCES_OBSERVED' ? 0 : 3,
      'intervalsObserved': status == 'MULTIPLE_APPEARANCES' ? 2 : 0,
      'verifiedIntervals': status == 'MULTIPLE_APPEARANCES' ? 2 : 0,
      'incompleteCoverageIntervals': 0,
      'minimumIntervalDays': status == 'MULTIPLE_APPEARANCES' ? 4 : null,
      'maximumIntervalDays': status == 'MULTIPLE_APPEARANCES' ? 11 : null,
      'averageIntervalDays': status == 'MULTIPLE_APPEARANCES' ? 7.5 : null,
      'medianIntervalDays': status == 'MULTIPLE_APPEARANCES' ? 7.5 : null,
      'latestIntervalDays': status == 'MULTIPLE_APPEARANCES' ? 11 : null,
      'lastAppearanceDate':
          status == 'NO_APPEARANCES_OBSERVED' ? null : '2026-10-23',
      'daysSinceLastAppearance':
          status == 'NO_APPEARANCES_OBSERVED' ? null : days,
    };

class FakeStatisticsRepository implements FirstPrizeStatisticsRepository {
  bool fail = false;
  int retries = 0;
  final requestedDrawIds = <String>[];

  @override
  Future<IntervalRankingResponse> getIntervals(
    StatisticsDrawOption draw,
    String coverage,
  ) async {
    retries += 1;
    requestedDrawIds.add(draw.drawId);
    if (fail) throw Exception('sin conexión');
    return IntervalRankingResponse.fromJson({
      'quality': qualityJson,
      'disclaimer': 'Histórico',
      'results': [
        {
          'days': 11,
          'distinctNumbers': 4,
          'totalRepetitions': 4,
          'numbers': ['03', '49', '82', '86']
        }
      ],
    });
  }

  @override
  Future<IntervalDetail> getIntervalDetail(
    StatisticsDrawOption draw,
    int days,
    String coverage,
  ) async {
    requestedDrawIds.add(draw.drawId);
    return IntervalDetail.fromJson({
      'days': days,
      'distinctNumbers': 1,
      'totalRepetitions': 1,
      'numbers': ['03'],
      'occurrences': {
        'results': [
          {
            'number': '03',
            'startDate': '2026-07-29',
            'endDate': '2026-08-09',
            'days': 11,
            'coverageStatus': 'VERIFIED',
            'blockingDates': []
          }
        ]
      }
    });
  }

  @override
  Future<NumberStatisticsResponse> getNumbers(
    StatisticsDrawOption draw,
  ) async {
    requestedDrawIds.add(draw.drawId);
    return NumberStatisticsResponse.fromJson({
      'asOfDate': '2026-10-28',
      'quality': qualityJson,
      'results': List.generate(100, (index) {
        final number = index.toString().padLeft(2, '0');
        return index == 0
            ? numberJson(number, status: 'NO_APPEARANCES_OBSERVED')
            : numberJson(number, days: index);
      }),
    });
  }
}

const enabledNational = StatisticsDrawOption(
  operatorId: StatisticsSeries.operatorId,
  drawId: '6966a6d1ea7015c3b8a3d47c',
  displayName: 'Lotería Nacional',
  available: true,
);

class DelayedStatisticsRepository extends FakeStatisticsRepository {
  final delayedGanaMas = Completer<IntervalRankingResponse>();

  @override
  Future<IntervalRankingResponse> getIntervals(
    StatisticsDrawOption draw,
    String coverage,
  ) {
    requestedDrawIds.add(draw.drawId);
    if (draw.drawId == StatisticsSeries.ganaMas.drawId) {
      return delayedGanaMas.future;
    }
    return Future.value(IntervalRankingResponse.fromJson({
      'quality': qualityJson,
      'disclaimer': 'Histórico',
      'results': [
        {
          'days': 7,
          'distinctNumbers': 1,
          'totalRepetitions': 1,
          'numbers': ['87']
        }
      ],
    }));
  }
}

void main() {
  test('parses the real ranking, quality and detail contracts', () {
    final ranking = IntervalRankingResponse.fromJson({
      'quality': qualityJson,
      'disclaimer': 'Histórico',
      'results': [
        {
          'days': 11,
          'distinctNumbers': 4,
          'totalRepetitions': 4,
          'numbers': ['03', '49']
        }
      ],
    });
    expect(ranking.results.single.days, 11);
    expect(ranking.quality.resultsAnalyzed, 181);
    expect(ranking.quality.unverifiedDates.single.status, 'UNVERIFIED');
  });

  test('parses absent and single-appearance number states', () {
    final absent = NumberStatistics.fromJson(
        numberJson('00', status: 'NO_APPEARANCES_OBSERVED'));
    final single = NumberStatistics.fromJson(
        numberJson('01', status: 'SINGLE_APPEARANCE'));
    expect(absent.lastAppearanceDate, isNull);
    expect(single.intervalsObserved, 0);
  });

  test('orders current situation in every supported direction', () async {
    final controller =
        FirstPrizeStatisticsController(FakeStatisticsRepository());
    await controller.loadNumbers();
    expect(controller.orderedCurrentNumbers.first.number, '99');
    controller.setCurrentOrder(CurrentNumberOrder.leastDays);
    expect(controller.orderedCurrentNumbers.first.number, '01');
    expect(controller.orderedCurrentNumbers.last.number, '00');
    controller.setCurrentOrder(CurrentNumberOrder.numberDescending);
    expect(controller.orderedCurrentNumbers.first.number, '99');
  });

  test('feature flag is disabled unless explicitly compiled in', () {
    expect(FirstPrizeStatisticsConfig.enabled, isFalse);
    expect(FirstPrizeStatisticsConfig.available, isFalse);
  });

  test('sends the selected structured series identifiers to the API', () async {
    Uri? requestedUri;
    final source = FirstPrizeStatisticsRemoteSource(
      baseUrl: 'https://statistics.test',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'quality': qualityJson,
            'disclaimer': 'Histórico',
            'results': [],
          }),
          200,
        );
      }),
    );

    await source.getIntervals(StatisticsSeries.ganaMas, 'verified');

    expect(requestedUri?.queryParameters['operatorId'],
        StatisticsSeries.ganaMas.operatorId);
    expect(requestedUri?.queryParameters['drawId'],
        StatisticsSeries.ganaMas.drawId);
    expect(requestedUri?.queryParameters['coverage'], 'verified');
  });

  test('clears old data and ignores a late response after changing draw',
      () async {
    final repository = DelayedStatisticsRepository();
    final controller = FirstPrizeStatisticsController(
      repository,
      draws: const [StatisticsSeries.ganaMas, enabledNational],
    );

    final oldRequest = controller.loadIntervals();
    await Future<void>.delayed(Duration.zero);
    final change = controller.selectDraw(enabledNational);
    expect(controller.intervals, isNull);
    await change;
    expect(controller.selectedDraw.drawId, enabledNational.drawId);
    expect(controller.intervals?.results.single.days, 7);

    repository.delayedGanaMas.complete(IntervalRankingResponse.fromJson({
      'quality': qualityJson,
      'disclaimer': 'Histórico',
      'results': [
        {
          'days': 11,
          'distinctNumbers': 4,
          'totalRepetitions': 4,
          'numbers': ['03', '49', '82', '86']
        }
      ],
    }));
    await oldRequest;

    expect(controller.intervals?.results.single.days, 7);
    expect(
        repository.requestedDrawIds,
        containsAll([
          StatisticsSeries.ganaMas.drawId,
          enabledNational.drawId,
        ]));
  });

  testWidgets('shows one active draw and disables unprepared Nacional',
      (tester) async {
    final repository = FakeStatisticsRepository();
    await tester.pumpWidget(MaterialApp(
      home: FirstPrizeStatisticsPage(repository: repository),
    ));
    await tester.pumpAndSettle();

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.where((chip) => chip.selected), hasLength(1));
    final national = tester.widget<ChoiceChip>(
      find.byKey(Key('draw-${StatisticsSeries.national.drawId}')),
    );
    expect(national.onSelected, isNull);
    expect(find.textContaining('Historial pendiente de preparación'),
        findsOneWidget);
    expect(
        repository.requestedDrawIds.toSet(), {StatisticsSeries.ganaMas.drawId});
  });

  testWidgets('shows ranking, coverage filter and interval detail',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home:
            FirstPrizeStatisticsPage(repository: FakeStatisticsRepository())));
    await tester.pumpAndSettle();
    expect(find.text('11 DÍAS'), findsOneWidget);
    expect(find.text('Verificados'), findsOneWidget);
    await tester.tap(find.byKey(const Key('interval-11')));
    await tester.pumpAndSettle();
    expect(find.text('Primera aparición: 29/07/2026'), findsOneWidget);
    expect(find.text('Cobertura verificada'), findsOneWidget);
  });

  testWidgets('shows incomplete coverage warning', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home:
            FirstPrizeStatisticsPage(repository: FakeStatisticsRepository())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incompletos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('fechas sin verificar'), findsOneWidget);
  });

  testWidgets('renders 00-99 and individual history states', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home:
            FirstPrizeStatisticsPage(repository: FakeStatisticsRepository())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Números'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('numbers-grid')), findsOneWidget);
    expect(find.byKey(const Key('number-00')), findsOneWidget);
    await tester.tap(find.byKey(const Key('number-00')));
    await tester.pumpAndSettle();
    expect(find.text('Estadísticas individuales'), findsOneWidget);
  });

  testWidgets('shows connection error and retries', (tester) async {
    final repository = FakeStatisticsRepository()..fail = true;
    await tester.pumpWidget(
        MaterialApp(home: FirstPrizeStatisticsPage(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar el análisis'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Reintentar').first);
    await tester.pumpAndSettle();
    expect(find.text('11 DÍAS'), findsOneWidget);
    expect(repository.retries, greaterThan(1));
  });

  for (final width in [320.0, 360.0, 390.0, 411.0]) {
    testWidgets('is responsive at ${width.toInt()} dp', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: FirstPrizeStatisticsPage(
              repository: FakeStatisticsRepository())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
