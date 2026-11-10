import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sorteosdominicanos_app/app/app_features.dart';
import 'package:sorteosdominicanos_app/data/favorites_repository.dart';
import 'package:sorteosdominicanos_app/data/favorites_session.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_remote_source.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_repository.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_session.dart';
import 'package:sorteosdominicanos_app/domain/lottery_result.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/lottery_details_page.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/results_page.dart';

class _MemoryFavoritesStore implements LotteryFavoritesStore {
  final Set<String> values;
  bool failWrites;
  int reads = 0;
  int writes = 0;

  _MemoryFavoritesStore({
    Set<String>? values,
    this.failWrites = false,
  }) : values = Set<String>.from(values ?? const <String>{});

  @override
  Future<Set<String>> getFavoriteLotteryIds() async {
    reads++;
    return Set<String>.from(values);
  }

  @override
  Future<bool> toggleFavoriteLottery(String id) async {
    writes++;
    if (failWrites) throw Exception('write failed');
    if (!values.add(id)) values.remove(id);
    return values.contains(id);
  }
}

class _ResultsLoader implements LotteryResultsLoader {
  int calls = 0;

  @override
  Future<LotteryResultsResponse> getLatestResults() async {
    calls++;
    return LotteryResultsResponse(
      updatedAt: '2026-11-10T12:00:00Z',
      results: [
        LotteryResult(
          lotteryName: 'Anguila',
          drawName: 'Anguila 8:00 PM',
          drawDate: '2026-11-10',
          numbers: const ['01', '02', '03'],
        ),
      ],
    );
  }
}

void main() {
  group('FavoritesSession', () {
    test('adds and removes a lottery without duplicates', () async {
      final store = _MemoryFavoritesStore();
      final session = FavoritesSession(store: store);

      expect(await session.toggleLottery('anguila'), isTrue);
      expect(session.favoriteLotteryIds, {'anguila'});
      expect(await session.toggleLottery('anguila'), isFalse);
      expect(session.favoriteLotteryIds, isEmpty);
      expect(store.writes, 2);
    });

    test('loads persisted favorites in a new session', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_lottery_ids': ['anguila', 'anguila'],
      });
      final first = FavoritesSession(store: FavoritesRepository());
      await first.load();
      expect(first.favoriteLotteryIds, {'anguila'});

      final reopened = FavoritesSession(store: FavoritesRepository());
      await reopened.load();
      expect(reopened.favoriteLotteryIds, {'anguila'});
    });

    test('rolls back optimistic state when storage fails', () async {
      final store = _MemoryFavoritesStore(failWrites: true);
      final session = FavoritesSession(store: store);

      final operation = session.toggleLottery('anguila');
      expect(session.isFavorite('anguila'), isTrue);
      await expectLater(operation, throwsException);
      expect(session.isFavorite('anguila'), isFalse);
      expect(session.error, isNotNull);
    });

    test('deduplicates repeated loads', () async {
      final store = _MemoryFavoritesStore(values: {'anguila'});
      final session = FavoritesSession(store: store);

      await Future.wait([session.load(), session.load()]);
      expect(store.reads, 1);
      expect(session.favoriteLotteryIds, {'anguila'});
    });
  });

  testWidgets('card toggles favorite and favorite filter stays synchronized',
      (tester) async {
    final resultsLoader = _ResultsLoader();
    final resultsSession = LotteryResultsSession(loader: resultsLoader);
    await resultsSession.load();
    final favoritesStore = _MemoryFavoritesStore();
    final favoritesSession = FavoritesSession(store: favoritesStore);
    await favoritesSession.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ResultsPage(
          resultsSession: resultsSession,
          favoritesSession: favoritesSession,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('favorite-lottery-anguila')),
    );
    await tester.pumpAndSettle();
    expect(favoritesSession.favoriteLotteryIds, {'anguila'});
    expect(find.text('Anguila se agregó a Favoritas.'), findsOneWidget);

    await tester.tap(find.text('Favoritas'));
    await tester.pump();
    expect(find.text('Anguila'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('favorite-lottery-anguila')),
    );
    await tester.pump();
    expect(favoritesSession.favoriteLotteryIds, isEmpty);
    expect(find.text('No tienes loterías favoritas'), findsOneWidget);
    expect(resultsLoader.calls, 1, reason: 'favorites must not reload results');
  });

  testWidgets('favorite card opens its lottery results', (tester) async {
    final resultsSession = LotteryResultsSession(loader: _ResultsLoader());
    await resultsSession.load();
    final favoritesSession = FavoritesSession(
      store: _MemoryFavoritesStore(values: {'anguila'}),
    );
    await favoritesSession.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ResultsPage(
          resultsSession: resultsSession,
          favoritesSession: favoritesSession,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Favoritas'));
    await tester.pump();
    final favoriteCard = find.text('Anguila').first;
    await tester.ensureVisible(favoriteCard);
    await tester.pumpAndSettle();
    await tester.tap(favoriteCard);
    await tester.pumpAndSettle();

    expect(find.byType(LotteryDetailsPage), findsOneWidget);
    expect(find.text('Recientes'), findsOneWidget);
  });

  testWidgets('storage error keeps card state and shows accessible feedback',
      (tester) async {
    final resultsSession = LotteryResultsSession(loader: _ResultsLoader());
    await resultsSession.load();
    final favoritesSession = FavoritesSession(
      store: _MemoryFavoritesStore(failWrites: true),
    );
    await favoritesSession.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ResultsPage(
          resultsSession: resultsSession,
          favoritesSession: favoritesSession,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('favorite-lottery-anguila')),
    );
    await tester.pumpAndSettle();

    expect(favoritesSession.favoriteLotteryIds, isEmpty);
    expect(
      find.text('No se pudo guardar el cambio en Favoritas.'),
      findsOneWidget,
    );
  });

  test('experimental feature flags remain disabled', () {
    expect(AppFeatures.dreamsNumbersEnabled, isFalse);
    expect(AppFeatures.historicalRelationsEnabled, isFalse);
  });
}
