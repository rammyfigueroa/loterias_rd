import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/domain/lottery_result.dart';
import 'package:sorteosdominicanos_app/features/results/application/lottery_catalog.dart';
import 'package:sorteosdominicanos_app/features/results/presentation/widgets/lottery_home_widgets.dart';

void main() {
  testWidgets('LotteryCard renders a lottery without a mapped logo',
      (tester) async {
    final group = LotteryGroup(
      id: 'sin logo',
      name: 'Sin Logo',
      results: [
        LotteryResult(
          lotteryName: 'Sin Logo',
          drawName: 'Sorteo',
          drawDate: '2026-09-23',
          numbers: const ['01'],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 165,
            height: 176,
            child: LotteryCard(
              group: group,
              isFavorite: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sin Logo'), findsOneWidget);
    expect(find.text('1 sorteo'), findsOneWidget);
  });

  testWidgets('LotteryCard shows today badge only when enabled',
      (tester) async {
    final group = LotteryGroup(
      id: 'anguila',
      name: 'Anguila',
      results: [
        LotteryResult(
          lotteryName: 'Anguila',
          drawName: 'Noche',
          drawDate: '2026-10-21',
          numbers: const ['01', '02', '03'],
        ),
      ],
    );

    Future<void> pumpCard(bool hasResultsToday) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 165,
              height: 176,
              child: LotteryCard(
                group: group,
                isFavorite: false,
                hasResultsToday: hasResultsToday,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
    }

    await pumpCard(true);
    expect(find.text('Hoy'), findsOneWidget);

    await pumpCard(false);
    expect(find.text('Hoy'), findsNothing);
  });

  testWidgets('RecentResultCard enlarges only groups of up to three numbers',
      (tester) async {
    LotteryResult item(List<String> numbers) => LotteryResult(
          lotteryName: 'Anguila',
          drawName: 'Anguila 7:30 PM',
          drawDate: '2026-10-21',
          numbers: numbers,
        );

    Future<Size> pumpResult(List<String> numbers) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: RecentResultCard(
                result: item(numbers),
                nowUtc: DateTime.utc(2026, 10, 21, 18),
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byKey(const ValueKey('result-ball-0')));
    }

    for (final count in [1, 2, 3]) {
      expect(
        await pumpResult(List.generate(count, (index) => '$index')),
        const Size.square(64),
      );
    }
    for (final count in [4, 5]) {
      expect(
        await pumpResult(List.generate(count, (index) => '$index')),
        const Size.square(39),
      );
    }
  });

  testWidgets('RecentResultCard shows only lottery and day-first date metadata',
      (tester) async {
    var tapped = false;
    final item = LotteryResult(
      lotteryName: 'Haiti Bolet',
      drawName: 'Haiti Bolet 7:30 PM',
      drawDate: '2026-10-21',
      numbers: const ['57', '27', '39'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentResultCard(
            result: item,
            nowUtc: DateTime.utc(2026, 10, 21, 18),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Haiti Bolet'), findsOneWidget);
    expect(find.text('Haiti Bolet 7:30 PM'), findsNothing);
    final dateAndTime = tester.widget<Text>(
      find.text('21/10/2026 · 7:30 PM'),
    );
    expect(dateAndTime.style?.color, const Color(0xFF15803D));
    expect(dateAndTime.style?.fontWeight, FontWeight.w600);
    expect(
      tester.getSize(find.byKey(const ValueKey('recent-result-logo'))),
      const Size.square(60),
    );

    await tester.tap(find.byType(RecentResultCard));
    expect(tapped, isTrue);
  });

  testWidgets('today card and larger balls fit supported scaled layouts',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = LotteryResult(
      lotteryName: 'Anguila',
      drawName: 'Anguila 8:00 PM',
      drawDate: '2026-10-21',
      numbers: const ['03', '06', '42'],
    );
    for (final width in [320.0, 360.0, 390.0, 411.0]) {
      tester.view.physicalSize = Size(width, 720);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: 144,
                    height: 174,
                    child: LotteryCard(
                      group: LotteryGroup(
                        id: 'anguila',
                        name: 'Anguila',
                        results: [item],
                      ),
                      isFavorite: true,
                      hasResultsToday: true,
                      onTap: () {},
                    ),
                  ),
                  RecentResultCard(
                    result: item,
                    nowUtc: DateTime.utc(2026, 10, 21, 18),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('21/10/2026 · 8:00 PM'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'width: $width');
    }
  });

  testWidgets('RecentResultCard keeps previous result metadata gray',
      (tester) async {
    final item = LotteryResult(
      lotteryName: 'Anguila',
      drawName: 'Anguila 8:00 PM',
      drawDate: '2026-10-20',
      numbers: const ['03', '06', '42'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentResultCard(
            result: item,
            nowUtc: DateTime.utc(2026, 10, 21, 18),
            onTap: () {},
          ),
        ),
      ),
    );

    final dateAndTime = tester.widget<Text>(
      find.byKey(const ValueKey('recent-result-date-time')),
    );
    expect(dateAndTime.data, '20/10/2026 · 8:00 PM');
    expect(dateAndTime.style?.color, const Color(0xFF64748B));
    expect(dateAndTime.style?.fontWeight, FontWeight.w400);
  });

  testWidgets('number balls wrap results with five numbers', (tester) async {
    final item = LotteryResult(
      lotteryName: 'Nacional',
      drawName: 'Juega + Pega +',
      drawDate: '2026-09-23',
      numbers: const ['01', '02', '03', '04', '05'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 150,
            child: ResultNumberBalls(result: item),
          ),
        ),
      ),
    );

    for (final number in item.numbers) {
      expect(find.text(number), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar reports entered text', (tester) async {
    var query = '';
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LotterySearchBar(
            controller: controller,
            focusNode: focusNode,
            onChanged: (value) => query = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'anguila 90');
    expect(query, 'anguila 90');
  });
}
