import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/data/favorites_repository.dart';
import 'package:sorteosdominicanos_app/data/favorites_session.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_remote_source.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_repository.dart';
import 'package:sorteosdominicanos_app/data/lottery_results_session.dart';
import 'package:sorteosdominicanos_app/domain/lottery_result.dart';
import 'package:sorteosdominicanos_app/features/results/application/lottery_catalog.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/lottery_details_page.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/results_page.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/stats_page.dart';

class _StaticLoader implements LotteryResultsLoader {
  @override
  Future<LotteryResultsResponse> getLatestResults() async =>
      LotteryResultsResponse(
        updatedAt: '2026-11-10T12:00:00Z',
        results: [
          LotteryResult(
            lotteryName: 'Anguila',
            drawName: 'Anguila 8:00 PM',
            drawDate: '2026-11-10',
            numbers: ['01', '02', '03'],
          ),
        ],
      );
}

class _MemoryFavorites implements LotteryFavoritesStore {
  final values = <String>{};

  @override
  Future<Set<String>> getFavoriteLotteryIds() async => Set.from(values);

  @override
  Future<bool> toggleFavoriteLottery(String id) async {
    if (!values.add(id)) values.remove(id);
    return values.contains(id);
  }
}

Future<LotteryResultsSession> _loadedResults() async {
  final session = LotteryResultsSession(loader: _StaticLoader());
  await session.load();
  return session;
}

Widget _scaledApp({
  required Widget home,
  required Size size,
  required double textScale,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScale),
    ),
    child: MaterialApp(home: home),
  );
}

void main() {
  for (final configuration in const [
    (Size(360, 640), 1.5),
    (Size(390, 700), 1.3),
  ]) {
    testWidgets(
        'home has no overflow at ${configuration.$1.width.toInt()} dp and ${configuration.$2}x text',
        (tester) async {
      final results = await _loadedResults();
      final favorites = FavoritesSession(store: _MemoryFavorites());
      await favorites.load();
      await tester.binding.setSurfaceSize(configuration.$1);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _scaledApp(
          size: configuration.$1,
          textScale: configuration.$2,
          home: ResultsPage(
            resultsSession: results,
            favoritesSession: favorites,
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home remains usable at 320 dp with 2x text and 48 dp favorite',
      (tester) async {
    final results = await _loadedResults();
    final favorites = FavoritesSession(store: _MemoryFavorites());
    await favorites.load();
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _scaledApp(
        size: const Size(320, 640),
        textScale: 2,
        home: ResultsPage(
          resultsSession: results,
          favoritesSession: favorites,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final favorite = find.byKey(const ValueKey('favorite-lottery-anguila'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(favorite, findsOneWidget);
    expect(tester.getSize(favorite).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(favorite).height, greaterThanOrEqualTo(48));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Agregar Anguila a favoritas',
      ),
      findsOneWidget,
    );
  });

  testWidgets('winning numbers have one descriptive semantic label',
      (tester) async {
    final results = await _loadedResults();
    final favorites = FavoritesSession(store: _MemoryFavorites());
    await favorites.load();
    final item = results.response!.results.single;

    await tester.pumpWidget(
      MaterialApp(
        home: LotteryDetailsPage(
          group: LotteryGroup(
            id: 'anguila',
            name: 'Anguila',
            results: [item],
          ),
          favoritesSession: favorites,
          nowUtc: DateTime.utc(2026, 11, 10, 16),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Números ganadores: 01, 02, 03'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Agregar Anguila a favoritas'),
      findsOneWidget,
    );
  });

  testWidgets('statistics scroll controls on reduced height and 2x text',
      (tester) async {
    final results = await _loadedResults();
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _scaledApp(
        size: const Size(320, 480),
        textScale: 2,
        home: StatsPage(
          resultsSession: results,
          nowUtc: DateTime.utc(2026, 11, 10, 16),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('statistics-controls-scroll')), findsOneWidget);
    final coldMode = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Estadística Fríos',
    );
    expect(coldMode, findsOneWidget);
    expect(tester.getSize(coldMode).height, greaterThanOrEqualTo(48));
  });
}
