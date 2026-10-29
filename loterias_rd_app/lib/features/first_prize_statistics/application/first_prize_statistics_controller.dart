import 'package:flutter/foundation.dart';

import '../data/first_prize_statistics_repository.dart';
import '../domain/first_prize_statistics.dart';
import 'statistics_comparison.dart';

enum StatisticsLoadState { loading, data, empty, error }

enum StatisticsMode { national, ganaMas, both }

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
        selectedDraw = draws.firstWhere(
          (draw) =>
              draw.available && draw.drawId == StatisticsSeries.ganaMas.drawId,
          orElse: () => draws.firstWhere((draw) => draw.available),
        );

  StatisticsDrawOption selectedDraw;
  StatisticsMode mode = StatisticsMode.ganaMas;
  final StatisticsComparison comparison = const StatisticsComparison();
  int _intervalRequestId = 0;
  int _numberRequestId = 0;

  StatisticsLoadState intervalState = StatisticsLoadState.loading;
  StatisticsLoadState numberState = StatisticsLoadState.loading;
  String coverage = 'verified';
  String? intervalError;
  String? numberError;
  IntervalRankingResponse? intervals;
  NumberStatisticsResponse? numbers;
  final Map<String, IntervalRankingResponse> intervalsByDraw = {};
  final Map<String, NumberStatisticsResponse> numbersByDraw = {};
  CurrentNumberOrder currentOrder = CurrentNumberOrder.mostDays;
  StatisticsDateRange? appliedRange;
  DateTime? pendingFrom;
  DateTime? pendingTo;
  String? rangeError;

  Future<void> load() async {
    await Future.wait([loadIntervals(), loadNumbers()]);
  }

  Future<void> loadIntervals([String? nextCoverage]) async {
    if (nextCoverage != null) coverage = nextCoverage;
    final requestId = ++_intervalRequestId;
    final requestedDraw = selectedDraw;
    final requestedMode = mode;
    intervals = null;
    intervalState = StatisticsLoadState.loading;
    intervalError = null;
    notifyListeners();
    try {
      final responses = await _loadIntervalResponses(requestedMode, coverage);
      if (requestId != _intervalRequestId ||
          requestedMode != mode ||
          (requestedMode != StatisticsMode.both &&
              requestedDraw.drawId != selectedDraw.drawId)) {
        return;
      }
      intervalsByDraw
        ..clear()
        ..addAll(responses);
      intervals = requestedMode == StatisticsMode.both
          ? null
          : responses[requestedDraw.drawId];
      intervalState = (requestedMode == StatisticsMode.both
              ? combinedIntervals.isEmpty
              : intervals!.results.isEmpty)
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
    final requestedMode = mode;
    numbers = null;
    numberState = StatisticsLoadState.loading;
    numberError = null;
    notifyListeners();
    try {
      final responses = await _loadNumberResponses(requestedMode);
      if (requestId != _numberRequestId ||
          requestedMode != mode ||
          (requestedMode != StatisticsMode.both &&
              requestedDraw.drawId != selectedDraw.drawId)) {
        return;
      }
      numbersByDraw
        ..clear()
        ..addAll(responses);
      numbers = requestedMode == StatisticsMode.both
          ? null
          : responses[requestedDraw.drawId];
      numberState = responses.values.every((value) => value.results.isEmpty)
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
    mode = draw.drawId == StatisticsSeries.national.drawId
        ? StatisticsMode.national
        : StatisticsMode.ganaMas;
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

  Future<void> selectMode(StatisticsMode value) async {
    if (value == mode) return;
    _intervalRequestId += 1;
    _numberRequestId += 1;
    mode = value;
    if (value != StatisticsMode.both) {
      selectedDraw = value == StatisticsMode.national
          ? StatisticsSeries.national
          : StatisticsSeries.ganaMas;
    }
    coverage = 'verified';
    intervals = null;
    numbers = null;
    intervalsByDraw.clear();
    numbersByDraw.clear();
    intervalError = null;
    numberError = null;
    intervalState = StatisticsLoadState.loading;
    numberState = StatisticsLoadState.loading;
    notifyListeners();
    await load();
  }

  Future<Map<String, IntervalRankingResponse>> _loadIntervalResponses(
      StatisticsMode requestedMode, String requestedCoverage) async {
    final requestedDraws = requestedMode == StatisticsMode.both
        ? const [StatisticsSeries.national, StatisticsSeries.ganaMas]
        : [selectedDraw];
    final values = await _loadEach(
      requestedDraws,
      (draw) =>
          repository.getIntervals(draw, requestedCoverage, range: appliedRange),
    );
    return {
      for (var i = 0; i < requestedDraws.length; i++)
        requestedDraws[i].drawId: values[i]
    };
  }

  Future<Map<String, NumberStatisticsResponse>> _loadNumberResponses(
      StatisticsMode requestedMode) async {
    final requestedDraws = requestedMode == StatisticsMode.both
        ? const [StatisticsSeries.national, StatisticsSeries.ganaMas]
        : [selectedDraw];
    final values = await _loadEach(
      requestedDraws,
      (draw) => repository.getNumbers(draw, range: appliedRange),
    );
    return {
      for (var i = 0; i < requestedDraws.length; i++)
        requestedDraws[i].drawId: values[i]
    };
  }

  Future<List<T>> _loadEach<T>(
    List<StatisticsDrawOption> requestedDraws,
    Future<T> Function(StatisticsDrawOption draw) loader,
  ) async {
    final results = await Future.wait(requestedDraws.map((draw) async {
      try {
        return (value: await loader(draw), error: null, draw: draw);
      } catch (error) {
        return (value: null, error: error, draw: draw);
      }
    }));
    final failures = results.where((result) => result.error != null).toList();
    if (failures.isNotEmpty) {
      final names =
          failures.map((result) => result.draw.displayName).join(', ');
      throw Exception(
          'No se pudo completar la comparación. Falló: $names. Reintenta para cargar ambas series.');
    }
    return results.map((result) => result.value as T).toList();
  }

  List<CombinedIntervalRanking> get combinedIntervals {
    final national = intervalsByDraw[StatisticsSeries.national.drawId];
    final ganaMas = intervalsByDraw[StatisticsSeries.ganaMas.drawId];
    if (national == null || ganaMas == null) return const [];
    return comparison.combineRankings(national, ganaMas);
  }

  List<SharedIntervalMatch> get sharedMatches {
    final national = intervalsByDraw[StatisticsSeries.national.drawId];
    final ganaMas = intervalsByDraw[StatisticsSeries.ganaMas.drawId];
    if (national == null || ganaMas == null) return const [];
    return comparison.sharedMatches(national, ganaMas);
  }

  NumberStatisticsResponse? numbersFor(StatisticsDrawOption draw) =>
      numbersByDraw[draw.drawId];

  ({DateTime? first, DateTime? last}) get availableRange {
    final qualities = mode == StatisticsMode.both
        ? intervalsByDraw.values.map((value) => value.quality).toList()
        : [if (intervals != null) intervals!.quality];
    final firstDates = qualities
        .map((quality) => DateTime.tryParse(quality.firstAvailableDate ?? ''))
        .whereType<DateTime>()
        .toList();
    final lastDates = qualities
        .map((quality) => DateTime.tryParse(quality.lastAvailableDate ?? ''))
        .whereType<DateTime>()
        .toList();
    if (firstDates.isEmpty || lastDates.isEmpty)
      return (first: null, last: null);
    firstDates.sort();
    lastDates.sort();
    return (
      first: mode == StatisticsMode.both ? firstDates.last : firstDates.first,
      last: mode == StatisticsMode.both ? lastDates.first : lastDates.last,
    );
  }

  void setPendingFrom(DateTime value) {
    pendingFrom = DateTime(value.year, value.month, value.day);
    rangeError = null;
    notifyListeners();
  }

  void setPendingTo(DateTime value) {
    pendingTo = DateTime(value.year, value.month, value.day);
    rangeError = null;
    notifyListeners();
  }

  Future<void> applyPendingRange() async {
    final available = availableRange;
    final from = pendingFrom ?? available.first;
    final to = pendingTo ?? available.last;
    if (from == null || to == null) {
      rangeError = 'Selecciona las fechas Desde y Hasta.';
    } else if (from.isAfter(to)) {
      rangeError = 'Desde no puede ser posterior a Hasta.';
    } else if ((available.first != null && from.isBefore(available.first!)) ||
        (available.last != null && to.isAfter(available.last!))) {
      rangeError = 'El rango debe estar dentro de la cobertura disponible.';
    } else {
      rangeError = null;
      appliedRange = StatisticsDateRange(from: from, to: to);
      _intervalRequestId += 1;
      _numberRequestId += 1;
      notifyListeners();
      await load();
      return;
    }
    notifyListeners();
  }

  Future<void> useFullHistory() async {
    pendingFrom = null;
    pendingTo = null;
    rangeError = null;
    if (appliedRange == null) {
      notifyListeners();
      return;
    }
    appliedRange = null;
    _intervalRequestId += 1;
    _numberRequestId += 1;
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
