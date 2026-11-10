import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/app/app_features.dart';
import 'package:sorteosdominicanos_app/features/first_prize_statistics/domain/first_prize_statistics.dart';
import 'package:sorteosdominicanos_app/features/historical_relations/application/historical_relations_controller.dart';
import 'package:sorteosdominicanos_app/features/historical_relations/data/historical_relations_repository.dart';
import 'package:sorteosdominicanos_app/features/historical_relations/domain/historical_relations.dart';
import 'package:sorteosdominicanos_app/features/historical_relations/presentation/historical_relations_navigation.dart';
import 'package:sorteosdominicanos_app/features/historical_relations/presentation/historical_relations_page.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

class ErrorRepository implements HistoricalRelationsRepository {
  @override
  Future<HistoricalRelationsResult> load(HistoricalRelationsQuery query) {
    return Future.error(StateError('synthetic failure'));
  }
}

class EmptyRepository implements HistoricalRelationsRepository {
  @override
  Future<HistoricalRelationsResult> load(HistoricalRelationsQuery query) async {
    return HistoricalRelationsResult(
      series: query.series,
      originNumber: query.originNumber,
      range: query.range,
      coverage: query.coverage,
      originAppearances: 0,
      totalTransitions: 0,
      quality: const HistoricalRelationsQuality(
        firstAvailableDate: '2026-04-01',
        lastAvailableDate: '2026-04-11',
        eventsAnalyzed: 16,
        verifiedTransitions: 15,
        incompleteCoverageTransitions: 0,
        originEventsWithoutSuccessor: 0,
        unverifiedDateCount: 0,
      ),
      destinations: const [],
      warnings: const [],
      disclaimer: 'No predice resultados futuros.',
    );
  }
}

class ControlledRepository implements HistoricalRelationsRepository {
  final requests = <HistoricalRelationsQuery>[];
  final completions = <Completer<HistoricalRelationsResult>>[];

  @override
  Future<HistoricalRelationsResult> load(HistoricalRelationsQuery query) {
    requests.add(query);
    final completer = Completer<HistoricalRelationsResult>();
    completions.add(completer);
    return completer.future;
  }
}

HistoricalRelationsResult responseFor(
  HistoricalRelationsQuery query,
  String nextNumber,
) {
  return HistoricalRelationsResult(
    series: query.series,
    originNumber: query.originNumber,
    range: query.range,
    coverage: query.coverage,
    originAppearances: 2,
    totalTransitions: 1,
    quality: const HistoricalRelationsQuality(
      firstAvailableDate: '2026-04-01',
      lastAvailableDate: '2026-04-11',
      eventsAnalyzed: 2,
      verifiedTransitions: 1,
      incompleteCoverageTransitions: 0,
      originEventsWithoutSuccessor: 1,
      unverifiedDateCount: 0,
    ),
    destinations: [
      HistoricalRelationDestination(
        nextNumber: nextNumber,
        transitionCount: 1,
        relativeFrequency: 1,
        lastTransitionDate: '2026-04-11',
      ),
    ],
    warnings: const [],
    disclaimer: 'No predice resultados futuros.',
  );
}

void main() {
  group('feature flag and navigation', () {
    test('both protected features remain disabled', () {
      expect(AppFeatures.historicalRelationsEnabled, isFalse);
      expect(AppFeatures.dreamsNumbersEnabled, isFalse);
    });

    testWidgets('entry is hidden when the flag is disabled', (tester) async {
      await tester
          .pumpWidget(app(const HistoricalRelationsEntry(enabled: false)));
      expect(find.text('Relaciones Históricas'), findsNothing);
    });

    testWidgets('navigation is blocked when disabled', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return TextButton(
            onPressed: () => openHistoricalRelations(context, enabled: false),
            child: const Text('Abrir'),
          );
        }),
      ));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoricalRelationsPage), findsNothing);
    });

    testWidgets('enabled entry opens the local screen', (tester) async {
      await tester.pumpWidget(app(HistoricalRelationsEntry(
        enabled: true,
        repository: LocalHistoricalRelationsRepository(delay: Duration.zero),
      )));
      await tester.tap(find.text('Relaciones Históricas'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoricalRelationsPage), findsOneWidget);
      expect(find.text('Números siguientes'), findsOneWidget);
    });
  });

  group('local repository and controller', () {
    test('synthetic response is deterministic and ordered', () async {
      final repository =
          LocalHistoricalRelationsRepository(delay: Duration.zero);
      final result = await repository.load(const HistoricalRelationsQuery(
        series: StatisticsSeries.ganaMas,
        originNumber: '24',
      ));
      expect(result.destinations.map((item) => item.nextNumber),
          ['67', '24', '32']);
      expect(
          result.destinations.map((item) => item.transitionCount), [3, 1, 1]);
      expect(result.totalTransitions, 5);
    });

    test('frequencies use observed transitions as denominator', () async {
      final repository =
          LocalHistoricalRelationsRepository(delay: Duration.zero);
      final result = await repository.load(const HistoricalRelationsQuery(
        series: StatisticsSeries.ganaMas,
        originNumber: '24',
      ));
      expect(result.destinations.map((item) => item.relativeFrequency),
          [0.6, 0.2, 0.2]);
    });

    test('cache includes series, number, range and coverage', () async {
      final repository =
          LocalHistoricalRelationsRepository(delay: Duration.zero);
      const base = HistoricalRelationsQuery(
        series: StatisticsSeries.ganaMas,
        originNumber: '24',
      );
      await repository.load(base);
      await repository.load(base);
      await repository.load(const HistoricalRelationsQuery(
        series: StatisticsSeries.national,
        originNumber: '24',
      ));
      await repository.load(const HistoricalRelationsQuery(
        series: StatisticsSeries.ganaMas,
        originNumber: '24',
        coverage: HistoricalCoverage.all,
      ));
      expect(repository.loadCount, 3);
      expect(repository.cacheSize, 3);
    });

    test('series and number selection remain independent', () async {
      final controller = HistoricalRelationsController(
        LocalHistoricalRelationsRepository(delay: Duration.zero),
      );
      await controller.selectSeries(StatisticsSeries.national);
      await controller.selectNumber('07');
      expect(controller.selectedSeries, StatisticsSeries.national);
      expect(controller.originNumber, '07');
      expect(controller.state, HistoricalRelationsLoadState.empty);
    });

    test('rejects incomplete and inverted date ranges', () async {
      final controller = HistoricalRelationsController(
        LocalHistoricalRelationsRepository(delay: Duration.zero),
      );
      expect(await controller.applyRange(), isFalse);
      expect(controller.rangeError, contains('Desde y Hasta'));
      controller.setPendingFrom(DateTime(2026, 4, 12));
      controller.setPendingTo(DateTime(2026, 4, 1));
      expect(await controller.applyRange(), isFalse);
      expect(controller.rangeError, contains('posterior'));
    });

    test('applies an inclusive custom range and clears it', () async {
      final controller = HistoricalRelationsController(
        LocalHistoricalRelationsRepository(delay: Duration.zero),
      );
      controller.setPendingFrom(DateTime(2026, 4, 1));
      controller.setPendingTo(DateTime(2026, 4, 11));
      expect(await controller.applyRange(), isTrue);
      expect(controller.appliedRange?.fromIso, '2026-04-01');
      expect(controller.appliedRange?.toIso, '2026-04-11');
      await controller.useAllHistory();
      expect(controller.appliedRange, isNull);
    });

    test('reports incomplete coverage without hiding it', () async {
      final controller = HistoricalRelationsController(
        LocalHistoricalRelationsRepository(delay: Duration.zero),
      );
      await controller.selectCoverage(HistoricalCoverage.all);
      expect(controller.result?.quality.incompleteCoverageTransitions, 1);
      expect(controller.result?.warnings, isNotEmpty);
    });

    test('exposes empty and error states', () async {
      final empty = HistoricalRelationsController(
        LocalHistoricalRelationsRepository(delay: Duration.zero),
      );
      await empty.selectNumber('99');
      expect(empty.state, HistoricalRelationsLoadState.empty);

      final failing = HistoricalRelationsController(ErrorRepository());
      await failing.load();
      expect(failing.state, HistoricalRelationsLoadState.error);
      expect(failing.errorMessage, isNotEmpty);
    });

    test('late responses cannot replace the active selection', () async {
      final repository = ControlledRepository();
      final controller = HistoricalRelationsController(repository);
      final first = controller.load();
      final second = controller.selectNumber('07');
      repository.completions[1]
          .complete(responseFor(repository.requests[1], '70'));
      await second;
      repository.completions[0]
          .complete(responseFor(repository.requests[0], '67'));
      await first;
      expect(controller.originNumber, '07');
      expect(controller.result?.destinations.single.nextNumber, '70');
    });
  });

  group('presentation and isolation', () {
    testWidgets('renders coverage, counts, dates and non-predictive language',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HistoricalRelationsPage(
          repository: LocalHistoricalRelationsRepository(delay: Duration.zero),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
      expect(find.textContaining('60.0 %'), findsOneWidget);
      expect(find.textContaining('11/04/2026'), findsWidgets);
      expect(
          find.textContaining('no predice resultados futuros'), findsOneWidget);
    });

    testWidgets('shows empty state for a number without transitions',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HistoricalRelationsPage(
          repository: EmptyRepository(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('historical-empty')), findsOneWidget);
    });

    testWidgets('fits a 320 dp wide screen without layout exceptions',
        (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: HistoricalRelationsPage(
          repository: LocalHistoricalRelationsRepository(delay: Duration.zero),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Relaciones Históricas'), findsOneWidget);
    });

    test('module contains no HTTP, URL or credential material', () {
      final directory = Directory('lib/features/historical_relations');
      final source = directory
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(source, isNot(contains('package:http')));
      expect(source, isNot(contains('https://')));
      expect(source.toLowerCase(), isNot(contains('access_token')));
      expect(source.toLowerCase(), isNot(contains('password')));
      expect(source, isNot(contains('Cloudflare')));
    });
  });
}
