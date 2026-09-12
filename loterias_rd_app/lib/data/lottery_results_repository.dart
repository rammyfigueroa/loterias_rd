import 'lottery_results_remote_source.dart';
import 'sample_data.dart';

/// Repository that decides whether to load data from the remote API or fall back
/// to sample data. If the API call throws, the sample data is returned.
class LotteryResultsRepository {
  final LotteryResultsRemoteSource remoteSource;
  final SampleLotteryResultsSource sampleSource;

  LotteryResultsRepository({
    required this.remoteSource,
    required this.sampleSource,
  });

  Future<LotteryResultsResponse> getLatestResults() async {
    return remoteSource.getLatestResults();
  }
}