import '../domain/first_prize_statistics.dart';
import 'first_prize_statistics_remote_source.dart';

abstract class FirstPrizeStatisticsRepository {
  Future<IntervalRankingResponse> getIntervals(String coverage);
  Future<IntervalDetail> getIntervalDetail(int days, String coverage);
  Future<NumberStatisticsResponse> getNumbers();
}

class RemoteFirstPrizeStatisticsRepository
    implements FirstPrizeStatisticsRepository {
  final FirstPrizeStatisticsRemoteSource remoteSource;

  const RemoteFirstPrizeStatisticsRepository(this.remoteSource);

  @override
  Future<IntervalRankingResponse> getIntervals(String coverage) =>
      remoteSource.getIntervals(coverage);

  @override
  Future<IntervalDetail> getIntervalDetail(int days, String coverage) =>
      remoteSource.getIntervalDetail(days, coverage);

  @override
  Future<NumberStatisticsResponse> getNumbers() => remoteSource.getNumbers();
}
