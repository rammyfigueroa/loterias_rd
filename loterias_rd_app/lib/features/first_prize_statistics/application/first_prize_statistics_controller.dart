import 'package:flutter/foundation.dart';

import '../data/first_prize_statistics_repository.dart';
import '../domain/first_prize_statistics.dart';

enum StatisticsLoadState { loading, data, empty, error }

enum CurrentNumberOrder {
  mostDays,
  leastDays,
  numberAscending,
  numberDescending
}

class FirstPrizeStatisticsController extends ChangeNotifier {
  final FirstPrizeStatisticsRepository repository;
  final List<StatisticsDrawOption> draws;

  FirstPrizeStatisticsController(
    this.repository, {
    List<StatisticsDrawOption> draws = StatisticsSeries.draws,
  })  : draws = List.unmodifiable(draws),
        selectedDraw = draws.firstWhere((draw) => draw.available);

  StatisticsDrawOption selectedDraw;
  int _intervalRequestId = 0;
  int _numberRequestId = 0;

  StatisticsLoadState intervalState = StatisticsLoadState.loading;
  StatisticsLoadState numberState = StatisticsLoadState.loading;
  String coverage = 'verified';
  String? intervalError;
  String? numberError;
  IntervalRankingResponse? intervals;
  NumberStatisticsResponse? numbers;
  CurrentNumberOrder currentOrder = CurrentNumberOrder.mostDays;

  Future<void> load() async {
    await Future.wait([loadIntervals(), loadNumbers()]);
  }

  Future<void> loadIntervals([String? nextCoverage]) async {
    if (nextCoverage != null) coverage = nextCoverage;
    final requestId = ++_intervalRequestId;
    final requestedDraw = selectedDraw;
    intervals = null;
    intervalState = StatisticsLoadState.loading;
    intervalError = null;
    notifyListeners();
    try {
      final response = await repository.getIntervals(requestedDraw, coverage);
      if (requestId != _intervalRequestId ||
          requestedDraw.drawId != selectedDraw.drawId) {
        return;
      }
      intervals = response;
      intervalState = response.results.isEmpty
          ? StatisticsLoadState.empty
          : StatisticsLoadState.data;
    } catch (error) {
      if (requestId != _intervalRequestId ||
          requestedDraw.drawId != selectedDraw.drawId) {
        return;
      }
      intervalError = error.toString();
      intervalState = StatisticsLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadNumbers() async {
    final requestId = ++_numberRequestId;
    final requestedDraw = selectedDraw;
    numbers = null;
    numberState = StatisticsLoadState.loading;
    numberError = null;
    notifyListeners();
    try {
      final response = await repository.getNumbers(requestedDraw);
      if (requestId != _numberRequestId ||
          requestedDraw.drawId != selectedDraw.drawId) {
        return;
      }
      numbers = response;
      numberState = response.results.isEmpty
          ? StatisticsLoadState.empty
          : StatisticsLoadState.data;
    } catch (error) {
      if (requestId != _numberRequestId ||
          requestedDraw.drawId != selectedDraw.drawId) {
        return;
      }
      numberError = error.toString();
      numberState = StatisticsLoadState.error;
    }
    notifyListeners();
  }

  Future<void> selectDraw(StatisticsDrawOption draw) async {
    if (!draw.available || draw.drawId == selectedDraw.drawId) return;
    _intervalRequestId += 1;
    _numberRequestId += 1;
    selectedDraw = draw;
    coverage = 'verified';
    intervals = null;
    numbers = null;
    intervalError = null;
    numberError = null;
    intervalState = StatisticsLoadState.loading;
    numberState = StatisticsLoadState.loading;
    notifyListeners();
    await load();
  }

  void setCurrentOrder(CurrentNumberOrder value) {
    currentOrder = value;
    notifyListeners();
  }

  List<NumberStatistics> get orderedCurrentNumbers {
    final result = [...?numbers?.results];
    int compareNullable(int? left, int? right) {
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    }

    result.sort((left, right) {
      switch (currentOrder) {
        case CurrentNumberOrder.mostDays:
          if (left.daysSinceLastAppearance == null) return 1;
          if (right.daysSinceLastAppearance == null) return -1;
          return right.daysSinceLastAppearance!
              .compareTo(left.daysSinceLastAppearance!);
        case CurrentNumberOrder.leastDays:
          return compareNullable(
              left.daysSinceLastAppearance, right.daysSinceLastAppearance);
        case CurrentNumberOrder.numberAscending:
          return left.number.compareTo(right.number);
        case CurrentNumberOrder.numberDescending:
          return right.number.compareTo(left.number);
      }
    });
    return result;
  }
}
