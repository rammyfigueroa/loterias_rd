import '../domain/historical_relations.dart';

abstract interface class HistoricalRelationsRepository {
  Future<HistoricalRelationsResult> load(HistoricalRelationsQuery query);
}

class LocalHistoricalRelationsRepository
    implements HistoricalRelationsRepository {
  final Duration delay;
  final Map<String, HistoricalRelationsResult> _cache = {};
  int loadCount = 0;

  LocalHistoricalRelationsRepository({
    this.delay = const Duration(milliseconds: 180),
  });

  int get cacheSize => _cache.length;

  @override
  Future<HistoricalRelationsResult> load(HistoricalRelationsQuery query) async {
    final cached = _cache[query.cacheKey];
    if (cached != null) return cached;
    loadCount += 1;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final result = _buildSyntheticResult(query);
    _cache[query.cacheKey] = result;
    return result;
  }

  HistoricalRelationsResult _buildSyntheticResult(
      HistoricalRelationsQuery query) {
    final allRows = <HistoricalRelationDestination>[
      const HistoricalRelationDestination(
        nextNumber: '67',
        transitionCount: 3,
        relativeFrequency: 0.6,
        lastTransitionDate: '2026-04-11',
      ),
      const HistoricalRelationDestination(
        nextNumber: '24',
        transitionCount: 1,
        relativeFrequency: 0.2,
        lastTransitionDate: '2026-04-09',
      ),
      const HistoricalRelationDestination(
        nextNumber: '32',
        transitionCount: 1,
        relativeFrequency: 0.2,
        lastTransitionDate: '2026-04-07',
      ),
    ];
    final rows = query.originNumber == '24'
        ? allRows
        : const <HistoricalRelationDestination>[];
    final incomplete = query.coverage != HistoricalCoverage.verified;
    return HistoricalRelationsResult(
      series: query.series,
      originNumber: query.originNumber,
      range: query.range,
      coverage: query.coverage,
      originAppearances: rows.isEmpty ? 0 : 6,
      totalTransitions: rows.isEmpty ? 0 : 5,
      quality: HistoricalRelationsQuality(
        firstAvailableDate: '2026-04-01',
        lastAvailableDate: '2026-04-11',
        eventsAnalyzed: 16,
        verifiedTransitions: 15,
        incompleteCoverageTransitions: incomplete ? 1 : 0,
        originEventsWithoutSuccessor: 1,
        unverifiedDateCount: incomplete ? 1 : 0,
      ),
      destinations: rows,
      warnings: incomplete
          ? const [
              'La cobertura seleccionada contiene una fecha no verificada.'
            ]
          : const [],
      disclaimer:
          'Este análisis describe transiciones históricas observadas y no predice resultados futuros.',
    );
  }
}
