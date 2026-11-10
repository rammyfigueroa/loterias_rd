import 'package:flutter/foundation.dart';

import '../../first_prize_statistics/domain/first_prize_statistics.dart';
import '../data/historical_relations_repository.dart';
import '../domain/historical_relations.dart';

class HistoricalRelationsController extends ChangeNotifier {
  final HistoricalRelationsRepository repository;
  final List<StatisticsDrawOption> seriesOptions;
  int _requestId = 0;

  HistoricalRelationsController(
    this.repository, {
    this.seriesOptions = StatisticsSeries.draws,
  }) : selectedSeries = seriesOptions.firstWhere((item) => item.available);

  StatisticsDrawOption selectedSeries;
  String originNumber = '24';
  HistoricalCoverage coverage = HistoricalCoverage.verified;
  DateTime? pendingFrom;
  DateTime? pendingTo;
  StatisticsDateRange? appliedRange;
  String? rangeError;
  String? errorMessage;
  HistoricalRelationsResult? result;
  HistoricalRelationsLoadState state = HistoricalRelationsLoadState.idle;

  HistoricalRelationsQuery get query => HistoricalRelationsQuery(
        series: selectedSeries,
        originNumber: originNumber,
        range: appliedRange,
        coverage: coverage,
      );

  Future<void> load() async {
    final requestId = ++_requestId;
    state = HistoricalRelationsLoadState.loading;
    result = null;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await repository.load(query);
      if (requestId != _requestId) return;
      result = response;
      state = response.destinations.isEmpty
          ? HistoricalRelationsLoadState.empty
          : HistoricalRelationsLoadState.data;
    } catch (_) {
      if (requestId != _requestId) return;
      errorMessage = 'No se pudieron cargar las relaciones históricas.';
      state = HistoricalRelationsLoadState.error;
    }
    notifyListeners();
  }

  Future<void> selectSeries(StatisticsDrawOption value) async {
    if (!value.available || value.drawId == selectedSeries.drawId) return;
    selectedSeries = value;
    await load();
  }

  Future<void> selectNumber(String value) async {
    final normalized = value.padLeft(2, '0');
    if (normalized == originNumber) return;
    originNumber = normalized;
    await load();
  }

  Future<void> selectCoverage(HistoricalCoverage value) async {
    if (value == coverage) return;
    coverage = value;
    await load();
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

  Future<bool> applyRange() async {
    if (pendingFrom == null || pendingTo == null) {
      rangeError = 'Selecciona las fechas Desde y Hasta.';
      notifyListeners();
      return false;
    }
    if (pendingFrom!.isAfter(pendingTo!)) {
      rangeError = 'Desde no puede ser posterior a Hasta.';
      notifyListeners();
      return false;
    }
    appliedRange = StatisticsDateRange(from: pendingFrom!, to: pendingTo!);
    rangeError = null;
    await load();
    return true;
  }

  Future<void> useAllHistory() async {
    pendingFrom = null;
    pendingTo = null;
    appliedRange = null;
    rangeError = null;
    await load();
  }
}
