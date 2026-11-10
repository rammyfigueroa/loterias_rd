import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_remote_source.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_repository.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_session.dart';
import 'package:sorteosdominicanos_app/domain/lottery_result.dart';
import 'package:sorteosdominicanos_app/features/results/application/lottery_catalog.dart';
import 'package:sorteosdominicanos_app/features/results/application/statistics_date_range_validator.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/stats_page.dart';

class _StaticResultsLoader implements LotteryResultsLoader {
  final LotteryResultsResponse response;
  int calls = 0;

  _StaticResultsLoader(this.response);

  @override
  Future<LotteryResultsResponse> getLatestResults() async {
    calls++;
    return response;
  }
}

class _QueuedResultsLoader implements LotteryResultsLoader {
  final List<Completer<LotteryResultsResponse>> requests = [];

  @override
  Future<LotteryResultsResponse> getLatestResults() {
    final completer = Completer<LotteryResultsResponse>();
    requests.add(completer);
    return completer.future;
  }
}

LotteryResultsResponse _response(List<LotteryResult> results) =>
    LotteryResultsResponse(
      updatedAt: '2026-11-10T12:00:00Z',
      results: results,
    );

LotteryResult _result(String date, List<String> numbers) => LotteryResult(
      lotteryName: 'Nacional',
      drawName: 'Gana Más',
      drawDate: date,
      numbers: numbers,
    );

void main() {
  final testNowUtc = DateTime.utc(2026, 11, 10, 16);

  group('StatisticsDateRangeValidator', () {
    final today = DateTime(2026, 11, 10);
    final coverageFrom = DateTime(2026, 10, 1);
    final coverageTo = DateTime(2026, 11, 10);

    test('accepts a complete valid range', () {
      final value = StatisticsDateRangeValidator.validate(
        from: DateTime(2026, 10, 2),
        to: DateTime(2026, 11, 9),
        today: today,
        coverageFrom: coverageFrom,
        coverageTo: coverageTo,
      );
      expect(value.isValid, isTrue);
    });

    test('accepts local picker dates against UTC coverage boundaries', () {
      final value = StatisticsDateRangeValidator.validate(
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 9),
        today: DateTime.utc(2026, 11, 10),
        coverageFrom: DateTime.utc(2026, 11, 1),
        coverageTo: DateTime.utc(2026, 11, 9),
      );

      expect(value.isValid, isTrue);
      expect(value.from, DateTime.utc(2026, 11, 1));
      expect(value.to, DateTime.utc(2026, 11, 9));
    });

    test('rejects inverted, future, outside and incomplete ranges', () {
      StatisticsDateRangeValidation validate(DateTime? from, DateTime? to) =>
          StatisticsDateRangeValidator.validate(
            from: from,
            to: to,
            today: today,
            coverageFrom: coverageFrom,
            coverageTo: coverageTo,
          );

      expect(
        validate(DateTime(2026, 11, 9), DateTime(2026, 11, 8)).error,
        contains('posterior'),
      );
      expect(
        validate(DateTime(2026, 11, 9), DateTime(2026, 11, 11)).error,
        contains('futuras'),
      );
      expect(
        validate(DateTime(2026, 9, 30), DateTime(2026, 10, 2)).error,
        contains('cobertura'),
      );
      expect(validate(DateTime(2026, 10, 2), null).error, contains('Hasta'));
    });

    test('existing parser rejects nonexistent calendar dates', () {
      expect(parseDrawDate('31/02/2026'), isNull);
      expect(parseDrawDate('2026-02-29'), isNull);
    });
  });

  testWidgets('shows verified sample size, period, coverage and disclaimer',
      (tester) async {
    final today = dominicanCalendarDate(testNowUtc);
    final yesterday = today.subtract(const Duration(days: 1));
    final loader = _StaticResultsLoader(
      _response([
        _result(_iso(today), const ['01', '02']),
        _result(_iso(yesterday), const ['03', '04', '05']),
      ]),
    );
    final session = LotteryResultsSession(loader: loader);
    await session.load();

    await tester.pumpWidget(
      MaterialApp(
        home: StatsPage(resultsSession: session, nowUtc: testNowUtc),
      ),
    );
    await tester.pump();

    expect(find.text('2 sorteos analizados · 5 apariciones'), findsOneWidget);
    expect(find.text('Período: Últimos 7 días'), findsOneWidget);
    expect(
      find.text(
        'Cobertura: ${formatCalendarDate(yesterday)} al ${formatCalendarDate(today)}',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Resumen histórico descriptivo; no predice resultados futuros.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty state without reusing another period',
      (tester) async {
    final loader = _StaticResultsLoader(
      _response([
        _result('2020-01-01', const ['01'])
      ]),
    );
    final session = LotteryResultsSession(loader: loader);
    await session.load();

    await tester.pumpWidget(
      MaterialApp(
        home: StatsPage(resultsSession: session, nowUtc: testNowUtc),
      ),
    );
    await tester.pump();

    expect(find.text('0 sorteos analizados · 0 apariciones'), findsOneWidget);
    expect(
      find.text('No hay datos suficientes para calcular estadísticas.'),
      findsOneWidget,
    );
  });

  testWidgets('incomplete custom range is rejected without showing old data',
      (tester) async {
    final today = dominicanCalendarDate(testNowUtc);
    final session = LotteryResultsSession(
      loader: _StaticResultsLoader(
        _response([
          _result(_iso(today), const ['01', '02'])
        ]),
      ),
    );
    await session.load();

    await tester.pumpWidget(
      MaterialApp(
        home: StatsPage(resultsSession: session, nowUtc: testNowUtc),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Rango'));
    await tester.pump();
    expect(find.text('0 sorteos analizados · 0 apariciones'), findsOneWidget);

    final applyRange = find.byKey(const Key('apply-local-statistics-range'));
    await tester.ensureVisible(applyRange);
    await tester.tap(applyRange);
    await tester.pump();
    expect(find.text('Selecciona las fechas Desde y Hasta.'), findsOneWidget);
    expect(find.text('0 sorteos analizados · 0 apariciones'), findsOneWidget);
  });

  testWidgets('applies a valid custom range and updates the sample summary',
      (tester) async {
    final loader = _StaticResultsLoader(
      _response([
        _result('2026-11-01', const ['01', '02']),
        _result('2026-11-09', const ['03', '04', '05']),
      ]),
    );
    final session = LotteryResultsSession(
      loader: loader,
    );
    await session.load();

    await tester.pumpWidget(
      MaterialApp(
        home: StatsPage(resultsSession: session, nowUtc: testNowUtc),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Rango'));
    await tester.pump();

    await tester.tap(find.text('Desde: --/--/----'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hasta: --/--/----'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final applyRange = find.byKey(const Key('apply-local-statistics-range'));
    await tester.ensureVisible(applyRange);
    await tester.tap(applyRange);
    await tester.pump();

    expect(find.text('Período: 01/11/2026 al 09/11/2026'), findsOneWidget);
    expect(find.text('2 sorteos analizados · 5 apariciones'), findsOneWidget);
    expect(find.text('No hay datos suficientes para calcular estadísticas.'),
        findsNothing);
    expect(loader.calls, 1);

    await tester.tap(find.text('Desde: 01/11/2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hasta: 09/11/2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(applyRange);
    await tester.tap(applyRange);
    await tester.pump();

    expect(find.text('Período: 02/11/2026 al 08/11/2026'), findsOneWidget);
    expect(find.text('0 sorteos analizados · 0 apariciones'), findsOneWidget);
    expect(find.text('No hay datos suficientes para calcular estadísticas.'),
        findsOneWidget);
    expect(loader.calls, 1);
  });

  testWidgets('keeps prior statistics on error and retries locally',
      (tester) async {
    final today = dominicanCalendarDate(testNowUtc);
    final loader = _QueuedResultsLoader();
    final session = LotteryResultsSession(loader: loader);
    final initial = session.load();
    loader.requests.single.complete(
      _response([
        _result(_iso(today), const ['07', '08'])
      ]),
    );
    await initial;

    await tester.pumpWidget(
      MaterialApp(
        home: StatsPage(resultsSession: session, nowUtc: testNowUtc),
      ),
    );
    await tester.pump();
    expect(find.text('1 sorteo analizado · 2 apariciones'), findsOneWidget);

    final failedRefresh = session.refresh();
    loader.requests.last.completeError(Exception('offline'));
    await expectLater(failedRefresh, throwsException);
    await tester.pump();
    expect(find.text('1 sorteo analizado · 2 apariciones'), findsOneWidget);
    expect(
      find.text(
        'No se pudo actualizar. Las estadísticas usan los resultados anteriores.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    loader.requests.last.complete(
      _response([
        _result(_iso(today), const ['09'])
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 sorteo analizado · 1 aparición'), findsOneWidget);
  });
}

String _iso(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
