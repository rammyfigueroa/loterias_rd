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
