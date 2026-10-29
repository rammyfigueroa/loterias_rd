import '../domain/first_prize_statistics.dart';
import 'first_prize_statistics_remote_source.dart';

abstract class FirstPrizeStatisticsRepository {
  Future<IntervalRankingResponse> getIntervals(
    StatisticsDrawOption draw,
    String coverage,
  );
  Future<IntervalDetail> getIntervalDetail(
    StatisticsDrawOption draw,
    int days,
    String coverage,
  );
  Future<NumberStatisticsResponse> getNumbers(StatisticsDrawOption draw);
}

class RemoteFirstPrizeStatisticsRepository
    implements FirstPrizeStatisticsRepository {
  final FirstPrizeStatisticsRemoteSource remoteSource;

  const RemoteFirstPrizeStatisticsRepository(this.remoteSource);

  @override
  Future<IntervalRankingResponse> getIntervals(
    StatisticsDrawOption draw,
    String coverage,
  ) =>
      remoteSource.getIntervals(draw, coverage);

  @override
  Future<IntervalDetail> getIntervalDetail(
    StatisticsDrawOption draw,
    int days,
    String coverage,
  ) =>
      remoteSource.getIntervalDetail(draw, days, coverage);

  @override
  Future<NumberStatisticsResponse> getNumbers(StatisticsDrawOption draw) =>
      remoteSource.getNumbers(draw);
}
