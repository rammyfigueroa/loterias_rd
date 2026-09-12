import '../domain/lottery_result.dart';
import 'lottery_results_remote_source.dart';

/// Simple in-memory fallback data source when the remote API fails.
class SampleLotteryResultsSource {
  Future<LotteryResultsResponse> getLatestResults() async {
    final results = <LotteryResult>[
      LotteryResult(
        lotteryName: 'Nacional',
        drawName: 'Quiniela',
        drawDate: '2026-05-28',
        numbers: ['13', '25', '38', '44', '49'],
        isVerified: true,
      ),
      LotteryResult(
        lotteryName: 'Leidsa',
        drawName: 'Loto',
        drawDate: '2026-05-28',
        numbers: ['5', '9', '16', '27', '32'],
        isVerified: true,
      ),
    ];
    return LotteryResultsResponse(
      updatedAt: DateTime.now().toIso8601String(),
      results: results,
    );
  }
}