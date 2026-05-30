import 'package:flutter_test/flutter_test.dart';
import 'package:loterias_rd_app/features/results/data/lottery_results_parser.dart';

void main() {
  test('parsea resultados desde texto visible similar a la web fuente', () {
    const html = '''
      <html>
        <body>
          <h2>Nacional</h2>
          <p>29-05</p>
          <a>Juega + Pega +</a>
          <p>13 16 19 26 25</p>
          <h2>Leidsa</h2>
          <p>28-05</p>
          <a>Quiniela Leidsa</a>
          <p>44 56 97</p>
        </body>
      </html>
    ''';

    final results = LotteryResultsParser().parse(html);

    expect(results, hasLength(2));
    expect(results.first.lotteryName, 'Nacional');
    expect(results.first.drawName, 'Juega + Pega +');
    expect(results.first.numbers, ['13', '16', '19', '26', '25']);
    expect(results.last.lotteryName, 'Leidsa');
  });
}
