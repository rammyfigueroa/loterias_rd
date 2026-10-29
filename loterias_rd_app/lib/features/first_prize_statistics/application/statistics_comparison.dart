import '../domain/first_prize_statistics.dart';

class CombinedIntervalRanking {
  final int days;
  final IntervalRanking? national;
  final IntervalRanking? ganaMas;

  const CombinedIntervalRanking({
    required this.days,
    required this.national,
    required this.ganaMas,
  });

  int get totalNumberDrawMatches =>
      (national?.distinctNumbers ?? 0) + (ganaMas?.distinctNumbers ?? 0);
  int get totalRepetitions =>
      (national?.totalRepetitions ?? 0) + (ganaMas?.totalRepetitions ?? 0);
  Set<String> get sharedNumbers => {
        ...?national?.numbers,
      }.intersection({...?ganaMas?.numbers});
}

class SharedIntervalMatch {
  final int days;
  final List<String> numbers;
  final int nationalRepetitions;
  final int ganaMasRepetitions;

  const SharedIntervalMatch({
    required this.days,
    required this.numbers,
    required this.nationalRepetitions,
    required this.ganaMasRepetitions,
  });

  int get totalRepetitions => nationalRepetitions + ganaMasRepetitions;
}

class StatisticsComparison {
  const StatisticsComparison();

  List<CombinedIntervalRanking> combineRankings(
    IntervalRankingResponse national,
    IntervalRankingResponse ganaMas,
  ) {
    final nationalByDays = {
      for (final item in national.results) item.days: item
    };
    final ganaMasByDays = {for (final item in ganaMas.results) item.days: item};
    final days = {...nationalByDays.keys, ...ganaMasByDays.keys};
    final result = days
        .map((value) => CombinedIntervalRanking(
              days: value,
              national: nationalByDays[value],
              ganaMas: ganaMasByDays[value],
            ))
        .toList();
    result.sort((left, right) {
      final byMatches =
          right.totalNumberDrawMatches.compareTo(left.totalNumberDrawMatches);
      if (byMatches != 0) return byMatches;
      final byRepetitions =
          right.totalRepetitions.compareTo(left.totalRepetitions);
      return byRepetitions != 0
          ? byRepetitions
          : left.days.compareTo(right.days);
    });
    return result;
  }

  List<SharedIntervalMatch> sharedMatches(
    IntervalRankingResponse national,
    IntervalRankingResponse ganaMas,
  ) {
    final combined = combineRankings(national, ganaMas);
    final result = combined
        .where((item) => item.sharedNumbers.isNotEmpty)
        .map((item) => SharedIntervalMatch(
              days: item.days,
              numbers: item.sharedNumbers.toList()..sort(),
              nationalRepetitions: item.national!.totalRepetitions,
              ganaMasRepetitions: item.ganaMas!.totalRepetitions,
            ))
        .toList();
    result.sort((left, right) {
      final byNumbers = right.numbers.length.compareTo(left.numbers.length);
      if (byNumbers != 0) return byNumbers;
      final byRepetitions =
          right.totalRepetitions.compareTo(left.totalRepetitions);
      return byRepetitions != 0
          ? byRepetitions
          : left.days.compareTo(right.days);
    });
    return result;
  }
}
