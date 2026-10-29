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
  final Map<String, IntervalRankingResponse> _intervalCache = {};
  final Map<String, IntervalDetail> _detailCache = {};
  final Map<String, NumberStatisticsResponse> _numberCache = {};

  RemoteFirstPrizeStatisticsRepository(this.remoteSource);

  @override
  Future<IntervalRankingResponse> getIntervals(
    StatisticsDrawOption draw,
    String coverage,
  ) async {
    final key = '${draw.operatorId}:${draw.drawId}:intervals:$coverage';
    return _intervalCache[key] ??=
        await remoteSource.getIntervals(draw, coverage);
  }

  @override
  Future<IntervalDetail> getIntervalDetail(
    StatisticsDrawOption draw,
    int days,
    String coverage,
  ) async {
    final key = '${draw.operatorId}:${draw.drawId}:detail:$days:$coverage';
    return _detailCache[key] ??=
        await remoteSource.getIntervalDetail(draw, days, coverage);
  }

  @override
  Future<NumberStatisticsResponse> getNumbers(StatisticsDrawOption draw) async {
    final key = '${draw.operatorId}:${draw.drawId}:numbers';
    return _numberCache[key] ??= await remoteSource.getNumbers(draw);
  }
}
