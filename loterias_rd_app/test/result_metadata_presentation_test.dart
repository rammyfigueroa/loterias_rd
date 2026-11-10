import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sorteosdominicanos_app/app/theme/app_theme.dart';
import 'package:sorteosdominicanos_app/data/favorites_repository.dart';
import 'package:sorteosdominicanos_app/data/favorites_session.dart';
import 'package:sorteosdominicanos_app/domain/lottery_result.dart';
import 'package:sorteosdominicanos_app/features/results/application/lottery_catalog.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/lottery_details_page.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/result_detail_page.dart';

void main() {
  const prizes = [
    LotteryPrize(position: 1, label: 'Primera', number: '27'),
    LotteryPrize(position: 2, label: 'Segunda', number: '22'),
    LotteryPrize(position: 3, label: 'Tercera', number: '80'),
  ];

  LotteryResult result(String date) => LotteryResult(
        lotteryName: 'Anguila',
        drawName: 'Anguila 7:30 PM',
        drawDate: date,
        numbers: const ['27', '22', '80'],
        prizes: prizes,
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lottery detail colors today prize metadata green',
      (tester) async {
    final item = result('2026-10-21');
    await tester.pumpWidget(
      MaterialApp(
        home: LotteryDetailsPage(
          group: LotteryGroup(
            id: 'anguila',
            name: 'Anguila',
            results: [item],
          ),
          favoritesSession: FavoritesSession(store: FavoritesRepository()),
          nowUtc: DateTime.utc(2026, 10, 21, 18),
        ),
      ),
    );

    final date = tester.widget<Text>(
      find.byKey(const ValueKey('lottery-result-date')),
    );
    final firstPrize = tester.widget<Text>(find.text('Primera: 27'));
    expect(date.data, '21/10/2026');
    expect(date.style?.color, AppTheme.todayResultMetadataColor);
    expect(firstPrize.style?.color, AppTheme.todayResultMetadataColor);
  });

  testWidgets('lottery history preserves previous metadata colors',
      (tester) async {
    final latest = result('2026-10-21');
    final previous = result('2026-10-20');
    await tester.pumpWidget(
      MaterialApp(
        home: LotteryDetailsPage(
          group: LotteryGroup(
            id: 'anguila',
            name: 'Anguila',
            results: [latest, previous],
          ),
          favoritesSession: FavoritesSession(store: FavoritesRepository()),
          nowUtc: DateTime.utc(2026, 10, 21, 18),
        ),
      ),
    );
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    final date = tester.widget<Text>(
      find.byKey(const ValueKey('lottery-result-date')),
    );
    final firstPrize = tester.widget<Text>(find.text('Primera: 27'));
    expect(date.data, '20/10/2026');
    expect(date.style?.color, const Color(0xFF64748B));
    expect(firstPrize.style?.color, isNot(AppTheme.todayResultMetadataColor));
  });

  testWidgets('full detail formats date and uses real prize labels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultDetailPage(
          result: result('2026-10-21'),
          nowUtc: DateTime.utc(2026, 10, 21, 18),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('21/10/2026'), findsOneWidget);
    for (final label in ['Primera', 'Segunda', 'Tercera']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, AppTheme.todayResultMetadataColor);
    }
  });
}
