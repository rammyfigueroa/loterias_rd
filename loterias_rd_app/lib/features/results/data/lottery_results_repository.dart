import '../domain/lottery_result.dart';
import 'lottery_results_remote_source.dart';
import 'sample_results.dart';

class LotteryResultsRepository {
  LotteryResultsRepository({LotteryResultsRemoteSource? remoteSource})
      : _remoteSource = remoteSource ?? LotteryResultsRemoteSource();

  final LotteryResultsRemoteSource _remoteSource;

  Future<LotteryResultsResponse> getLatestResults() async {
    try {
      final results = await _remoteSource.fetchLatestResults();
      return LotteryResultsResponse(
        results: results,
        loadedFromFallback: false,
        message: 'Resultados actualizados desde la fuente web.',
      );
    } catch (error) {
      return LotteryResultsResponse(
        results: sampleResults,
        loadedFromFallback: true,
        message:
            'Mostrando resultados de muestra. Revisa la conexion o la fuente de datos.',
      );
    }
  }
}

class LotteryResultsResponse {
  const LotteryResultsResponse({
    required this.results,
    required this.loadedFromFallback,
    required this.message,
  });

  final List<LotteryResult> results;
  final bool loadedFromFallback;
  final String message;
}
