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

  FirstPrizeStatisticsController(this.repository);

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
    intervalState = StatisticsLoadState.loading;
    intervalError = null;
    notifyListeners();
    try {
      intervals = await repository.getIntervals(coverage);
      intervalState = intervals!.results.isEmpty
          ? StatisticsLoadState.empty
          : StatisticsLoadState.data;
    } catch (error) {
      intervalError = error.toString();
      intervalState = StatisticsLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadNumbers() async {
    numberState = StatisticsLoadState.loading;
    numberError = null;
    notifyListeners();
    try {
      numbers = await repository.getNumbers();
      numberState = numbers!.results.isEmpty
          ? StatisticsLoadState.empty
          : StatisticsLoadState.data;
    } catch (error) {
      numberError = error.toString();
      numberState = StatisticsLoadState.error;
    }
    notifyListeners();
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
