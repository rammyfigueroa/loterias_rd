import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_remote_source.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_repository.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_session.dart';
import 'package:sorteosdominicanos_app/domain/lottery_result.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/results_page.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/stats_page.dart';

class _QueuedLoader implements LotteryResultsLoader {
  final List<Completer<LotteryResultsResponse>> requests = [];

  int get calls => requests.length;

  @override
  Future<LotteryResultsResponse> getLatestResults() {
    final completer = Completer<LotteryResultsResponse>();
    requests.add(completer);
    return completer.future;
  }
}

LotteryResultsResponse _response(String number, {String? updatedAt}) {
  return LotteryResultsResponse(
    updatedAt: updatedAt ?? '2026-11-10T12:00:00Z',
    results: [
      LotteryResult(
        lotteryName: 'Nacional',
        drawName: 'Gana Más 2:30 PM',
        drawDate: '2026-11-10',
        numbers: [number],
      ),
    ],
  );
}

void main() {
  group('LotteryResultsSession', () {
    test('distinguishes initial loading from a successful first load',
        () async {
      final loader = _QueuedLoader();
      final session = LotteryResultsSession(loader: loader);

      final future = session.load();
      expect(session.state, LotteryResultsSessionState.loading);
      expect(session.hasData, isFalse);

      loader.requests.single.complete(_response('01'));
      await future;
      expect(session.state, LotteryResultsSessionState.ready);
      expect(session.response?.results.single.numbers, ['01']);
    });

    test('deduplicates simultaneous requests for the same resource', () async {
      final loader = _QueuedLoader();
      final session = LotteryResultsSession(loader: loader);

      final first = session.load();
      final second = session.load(forceRefresh: true);
      expect(loader.calls, 1);

      loader.requests.single.complete(_response('02'));
      expect((await first).results.single.numbers, ['02']);
      expect((await second).results.single.numbers, ['02']);
    });

    test('uses a valid cache without another request', () async {
      var now = DateTime(2026, 11, 10, 8);
      final loader = _QueuedLoader();
      final session = LotteryResultsSession(loader: loader, now: () => now);

      final first = session.load();
      loader.requests.single.complete(_response('03'));
      await first;
      now = now.add(const Duration(minutes: 4));

      await session.load();
      expect(loader.calls, 1);
      expect(session.isCacheFresh, isTrue);
    });

    test('refreshes an expired cache while preserving visible data', () async {
      var now = DateTime(2026, 11, 10, 8);
      final loader = _QueuedLoader();
      final session = LotteryResultsSession(loader: loader, now: () => now);

      final first = session.load();
      loader.requests.single.complete(_response('04'));
      await first;
      now = now.add(const Duration(minutes: 5));

      final expired = session.load();
      expect(loader.calls, 2);
      expect(session.state, LotteryResultsSessionState.refreshing);
      expect(session.response?.results.single.numbers, ['04']);
      loader.requests.last.complete(_response('05'));
      await expired;
      expect(session.response?.results.single.numbers, ['05']);
    });

    test('keeps previous data when a refresh fails', () async {
      final loader = _QueuedLoader();
      final session = LotteryResultsSession(loader: loader);
      final first = session.load();
      loader.requests.single.complete(_response('06'));
      await first;

      final refresh = session.refresh();
      loader.requests.last.completeError(Exception('network'));
      await expectLater(refresh, throwsException);

      expect(session.state, LotteryResultsSessionState.error);
      expect(session.error, isNotNull);
      expect(session.response?.results.single.numbers, ['06']);
    });

    test('reports an error without fabricating data on first load', () async {
      final loader = _QueuedLoader();
      final session = LotteryResultsSession(loader: loader);

      final load = session.load();
      loader.requests.single.completeError(Exception('offline'));
      await expectLater(load, throwsException);

      expect(session.state, LotteryResultsSessionState.error);
      expect(session.hasData, isFalse);
    });

    test('invalidation prevents a late response from replacing newer data',
        () async {
      final loader = _QueuedLoader();
      final session = LotteryResultsSession(loader: loader);

      final oldRequest = session.load();
      session.invalidate();
      final newRequest = session.load();
      expect(loader.calls, 2);

      loader.requests.last.complete(_response('08'));
      await newRequest;
      loader.requests.first.complete(_response('07'));
      await oldRequest;

      expect(session.response?.results.single.numbers, ['08']);
    });

    test('clear invalidation removes data and requires a new load', () async {
      final loader = _QueuedLoader();
      final session = LotteryResultsSession(loader: loader);
      final first = session.load();
      loader.requests.single.complete(_response('09'));
      await first;

      session.invalidate(clearData: true);
      expect(session.state, LotteryResultsSessionState.idle);
      expect(session.hasData, isFalse);

      final second = session.load();
      loader.requests.last.complete(_response('10'));
      await second;
      expect(loader.calls, 2);
    });

    test('separate sessions never mix incompatible resources', () async {
      final currentLoader = _QueuedLoader();
      final otherLoader = _QueuedLoader();
      final current = LotteryResultsSession(loader: currentLoader);
      final other = LotteryResultsSession(loader: otherLoader);

      final currentLoad = current.load();
      final otherLoad = other.load();
      currentLoader.requests.single.complete(_response('11'));
      otherLoader.requests.single.complete(_response('12'));
      await Future.wait([currentLoad, otherLoad]);

      expect(current.response?.results.single.numbers, ['11']);
      expect(other.response?.results.single.numbers, ['12']);
    });
  });

  testWidgets('StatsPage reuses a fresh shared session without another request',
      (tester) async {
    final loader = _QueuedLoader();
    final session = LotteryResultsSession(loader: loader);
    final initial = session.load();
    loader.requests.single.complete(_response('13'));
    await initial;

    await tester.pumpWidget(
      MaterialApp(home: StatsPage(resultsSession: session)),
    );
    await tester.pump();

    expect(loader.calls, 1);
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('refresh keeps results visible and replaces them on success',
      (tester) async {
    final loader = _QueuedLoader();
    final session = LotteryResultsSession(loader: loader);
    final initial = session.load();
    loader.requests.single.complete(_response('14'));
    await initial;

    await tester.pumpWidget(
      MaterialApp(home: ResultsPage(resultsSession: session)),
    );
    await tester.pump();
    expect(find.text('Nacional'), findsWidgets);

    final refresh = session.refresh();
    await tester.pump();
    expect(find.text('Nacional'), findsWidgets);
    expect(find.text('Actualizando resultados...'), findsOneWidget);
    expect(session.response?.results.single.numbers, ['14']);

    loader.requests.last.complete(_response('15'));
    await refresh;
    await tester.pump();
    expect(session.response?.results.single.numbers, ['15']);
    expect(find.text('Actualizando resultados...'), findsNothing);
  });

  testWidgets('failed refresh keeps results and offers retry', (tester) async {
    final loader = _QueuedLoader();
    final session = LotteryResultsSession(loader: loader);
    final initial = session.load();
    loader.requests.single.complete(_response('16'));
    await initial;

    await tester.pumpWidget(
      MaterialApp(home: ResultsPage(resultsSession: session)),
    );
    await tester.pump();

    final refresh = session.refresh();
    await tester.pump();
    loader.requests.last.completeError(Exception('offline'));
    await expectLater(refresh, throwsException);
    await tester.pump();

    expect(session.response?.results.single.numbers, ['16']);
    expect(find.text('Nacional'), findsWidgets);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(
      find.text('No se pudo actualizar. Mostrando datos anteriores.'),
      findsOneWidget,
    );
  });

  testWidgets('switching from Home to Stats shares the same cached request',
      (tester) async {
    final loader = _QueuedLoader();
    final session = LotteryResultsSession(loader: loader);
    final initial = session.load();
    loader.requests.single.complete(_response('17'));
    await initial;

    await tester.pumpWidget(
      MaterialApp(home: ResultsPage(resultsSession: session)),
    );
    await tester.pump();
    expect(find.byType(ResultsPage), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: StatsPage(resultsSession: session)),
    );
    await tester.pump();

    expect(find.byType(StatsPage), findsOneWidget);
    expect(loader.calls, 1);
  });
}
