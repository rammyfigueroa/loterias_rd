import '../../first_prize_statistics/domain/first_prize_statistics.dart';

enum HistoricalRelationsLoadState { idle, loading, data, empty, error }

enum HistoricalCoverage { verified, incomplete, all }

extension HistoricalCoverageValue on HistoricalCoverage {
  String get apiValue => switch (this) {
        HistoricalCoverage.verified => 'verified',
        HistoricalCoverage.incomplete => 'incomplete',
        HistoricalCoverage.all => 'all',
      };

  String get label => switch (this) {
        HistoricalCoverage.verified => 'Verificada',
        HistoricalCoverage.incomplete => 'Incompleta',
        HistoricalCoverage.all => 'Toda',
      };
}

class HistoricalRelationsQuery {
  final StatisticsDrawOption series;
  final String originNumber;
  final StatisticsDateRange? range;
  final HistoricalCoverage coverage;

  const HistoricalRelationsQuery({
    required this.series,
    required this.originNumber,
    this.range,
    this.coverage = HistoricalCoverage.verified,
  });

  String get cacheKey => [
        series.operatorId,
        series.drawId,
        'first',
        originNumber,
        range?.fromIso ?? '*',
        range?.toIso ?? '*',
        coverage.apiValue,
      ].join(':');
}

class HistoricalRelationsQuality {
  final String? firstAvailableDate;
  final String? lastAvailableDate;
  final int eventsAnalyzed;
  final int verifiedTransitions;
  final int incompleteCoverageTransitions;
  final int originEventsWithoutSuccessor;
  final int unverifiedDateCount;

  const HistoricalRelationsQuality({
    required this.firstAvailableDate,
    required this.lastAvailableDate,
    required this.eventsAnalyzed,
    required this.verifiedTransitions,
    required this.incompleteCoverageTransitions,
    required this.originEventsWithoutSuccessor,
    required this.unverifiedDateCount,
  });
}

class HistoricalRelationDestination {
  final String nextNumber;
  final int transitionCount;
  final double relativeFrequency;
  final String? lastTransitionDate;

  const HistoricalRelationDestination({
    required this.nextNumber,
    required this.transitionCount,
    required this.relativeFrequency,
    required this.lastTransitionDate,
  });
}

class HistoricalRelationsResult {
  final StatisticsDrawOption series;
  final String originNumber;
  final StatisticsDateRange? range;
  final HistoricalCoverage coverage;
  final int originAppearances;
  final int totalTransitions;
  final HistoricalRelationsQuality quality;
  final List<HistoricalRelationDestination> destinations;
  final List<String> warnings;
  final String disclaimer;

  HistoricalRelationsResult({
    required this.series,
    required this.originNumber,
    required this.range,
    required this.coverage,
    required this.originAppearances,
    required this.totalTransitions,
    required this.quality,
    required List<HistoricalRelationDestination> destinations,
    required List<String> warnings,
    required this.disclaimer,
  })  : destinations = List.unmodifiable(destinations),
        warnings = List.unmodifiable(warnings);
}
