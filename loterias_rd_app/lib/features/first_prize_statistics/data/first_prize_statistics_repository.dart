import '../domain/first_prize_statistics.dart';
import 'first_prize_statistics_remote_source.dart';

abstract class FirstPrizeStatisticsRepository {
  Future<IntervalRankingResponse> getIntervals(
      StatisticsDrawOption draw, String coverage,
      {StatisticsDateRange? range});
  Future<IntervalDetail> getIntervalDetail(
      StatisticsDrawOption draw, int days, String coverage,
      {StatisticsDateRange? range});
  Future<NumberStatisticsResponse> getNumbers(StatisticsDrawOption draw,
      {StatisticsDateRange? range});
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
      StatisticsDrawOption draw, String coverage,
      {StatisticsDateRange? range}) async {
    final key =
        '${draw.operatorId}:${draw.drawId}:intervals:$coverage:${range?.fromIso ?? '*'}:${range?.toIso ?? '*'}';
    return _intervalCache[key] ??=
        await remoteSource.getIntervals(draw, coverage, range: range);
  }

  @override
  Future<IntervalDetail> getIntervalDetail(
      StatisticsDrawOption draw, int days, String coverage,
      {StatisticsDateRange? range}) async {
    final key =
        '${draw.operatorId}:${draw.drawId}:detail:$days:$coverage:${range?.fromIso ?? '*'}:${range?.toIso ?? '*'}';
    return _detailCache[key] ??= await remoteSource
        .getIntervalDetail(draw, days, coverage, range: range);
  }

  @override
  Future<NumberStatisticsResponse> getNumbers(StatisticsDrawOption draw,
      {StatisticsDateRange? range}) async {
    final key =
        '${draw.operatorId}:${draw.drawId}:numbers:${range?.fromIso ?? '*'}:${range?.toIso ?? '*'}';
    return _numberCache[key] ??=
        await remoteSource.getNumbers(draw, range: range);
  }
}
