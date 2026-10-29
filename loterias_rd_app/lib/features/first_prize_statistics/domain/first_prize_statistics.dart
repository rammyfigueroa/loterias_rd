class StatisticsSeries {
  static const operatorId = '6966a6d1ea7015c3b8a3d477';
  static const operatorName = 'Nacional';
  static const prizeName = 'Primera posición';

  static const national = StatisticsDrawOption(
    operatorId: operatorId,
    drawId: '6966a6d1ea7015c3b8a3d47c',
    displayName: 'Lotería Nacional',
    available: false,
    unavailableReason: 'Historial pendiente de preparación',
  );

  static const ganaMas = StatisticsDrawOption(
    operatorId: operatorId,
    drawId: '6966a6d1ea7015c3b8a3d482',
    displayName: 'Gana Más',
    available: true,
  );

  static const draws = [national, ganaMas];
}

class StatisticsDrawOption {
  final String operatorId;
  final String drawId;
  final String displayName;
  final bool available;
  final String? unavailableReason;

  const StatisticsDrawOption({
    required this.operatorId,
    required this.drawId,
    required this.displayName,
    required this.available,
    this.unavailableReason,
  });
}

int _integer(Object? value) => value is num ? value.toInt() : 0;
double? _decimal(Object? value) => value is num ? value.toDouble() : null;
String? _text(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

class StatisticsQuality {
  final String? firstAvailableDate;
  final String? lastAvailableDate;
  final int resultsAnalyzed;
  final int verifiedIntervals;
  final int incompleteCoverageIntervals;
  final List<UnverifiedDate> unverifiedDates;

  const StatisticsQuality({
    required this.firstAvailableDate,
    required this.lastAvailableDate,
    required this.resultsAnalyzed,
    required this.verifiedIntervals,
    required this.incompleteCoverageIntervals,
    required this.unverifiedDates,
  });

  factory StatisticsQuality.fromJson(Map<String, dynamic> json) {
    return StatisticsQuality(
      firstAvailableDate: _text(json['firstAvailableDate']),
      lastAvailableDate: _text(json['lastAvailableDate']),
      resultsAnalyzed: _integer(json['resultsAnalyzed']),
      verifiedIntervals: _integer(json['verifiedIntervals']),
      incompleteCoverageIntervals:
          _integer(json['incompleteCoverageIntervals']),
      unverifiedDates: (json['unverifiedDates'] as List? ?? const [])
          .whereType<Map>()
          .map((item) =>
              UnverifiedDate.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class UnverifiedDate {
  final String date;
  final String status;

  const UnverifiedDate({required this.date, required this.status});

  factory UnverifiedDate.fromJson(Map<String, dynamic> json) => UnverifiedDate(
        date: _text(json['date']) ?? '',
        status: _text(json['status']) ?? 'UNKNOWN',
      );
}

class IntervalRanking {
  final int days;
  final int distinctNumbers;
  final int totalRepetitions;
  final List<String> numbers;

  const IntervalRanking({
    required this.days,
    required this.distinctNumbers,
    required this.totalRepetitions,
    required this.numbers,
  });

  factory IntervalRanking.fromJson(Map<String, dynamic> json) =>
      IntervalRanking(
        days: _integer(json['days']),
        distinctNumbers: _integer(json['distinctNumbers']),
        totalRepetitions: _integer(json['totalRepetitions']),
        numbers: (json['numbers'] as List? ?? const [])
            .map((item) => '$item')
            .toList(),
      );
}

class IntervalRankingResponse {
  final StatisticsQuality quality;
  final List<IntervalRanking> results;
  final String disclaimer;

  const IntervalRankingResponse({
    required this.quality,
    required this.results,
    required this.disclaimer,
  });

  factory IntervalRankingResponse.fromJson(Map<String, dynamic> json) {
    return IntervalRankingResponse(
      quality: StatisticsQuality.fromJson(
          Map<String, dynamic>.from(json['quality'] as Map)),
      results: (json['results'] as List? ?? const [])
          .whereType<Map>()
          .map((item) =>
              IntervalRanking.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      disclaimer: _text(json['disclaimer']) ?? '',
    );
  }
}

class IntervalOccurrence {
  final String number;
  final String startDate;
  final String endDate;
  final int days;
  final String coverageStatus;
  final List<UnverifiedDate> blockingDates;

  const IntervalOccurrence({
    required this.number,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.coverageStatus,
    required this.blockingDates,
  });

  factory IntervalOccurrence.fromJson(Map<String, dynamic> json) =>
      IntervalOccurrence(
        number: _text(json['number']) ?? '',
        startDate: _text(json['startDate']) ?? '',
        endDate: _text(json['endDate']) ?? '',
        days: _integer(json['days']),
        coverageStatus: _text(json['coverageStatus']) ?? 'INCOMPLETE_COVERAGE',
        blockingDates: (json['blockingDates'] as List? ?? const [])
            .whereType<Map>()
            .map((item) =>
                UnverifiedDate.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
}

class IntervalDetail {
  final int days;
  final int distinctNumbers;
  final int totalRepetitions;
  final List<String> numbers;
  final List<IntervalOccurrence> occurrences;

  const IntervalDetail({
    required this.days,
    required this.distinctNumbers,
    required this.totalRepetitions,
    required this.numbers,
    required this.occurrences,
  });

  factory IntervalDetail.fromJson(Map<String, dynamic> json) {
    final occurrencePage =
        Map<String, dynamic>.from(json['occurrences'] as Map);
    return IntervalDetail(
      days: _integer(json['days']),
      distinctNumbers: _integer(json['distinctNumbers']),
      totalRepetitions: _integer(json['totalRepetitions']),
      numbers: (json['numbers'] as List? ?? const [])
          .map((item) => '$item')
          .toList(),
      occurrences: (occurrencePage['results'] as List? ?? const [])
          .whereType<Map>()
          .map((item) =>
              IntervalOccurrence.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class NumberStatistics {
  final String number;
  final String sampleStatus;
  final int appearancesObserved;
  final int intervalsObserved;
  final int verifiedIntervals;
  final int incompleteCoverageIntervals;
  final int? minimumIntervalDays;
  final int? maximumIntervalDays;
  final double? averageIntervalDays;
  final double? medianIntervalDays;
  final int? latestIntervalDays;
  final String? lastAppearanceDate;
  final int? daysSinceLastAppearance;

  const NumberStatistics({
    required this.number,
    required this.sampleStatus,
    required this.appearancesObserved,
    required this.intervalsObserved,
    required this.verifiedIntervals,
    required this.incompleteCoverageIntervals,
    required this.minimumIntervalDays,
    required this.maximumIntervalDays,
    required this.averageIntervalDays,
    required this.medianIntervalDays,
    required this.latestIntervalDays,
    required this.lastAppearanceDate,
    required this.daysSinceLastAppearance,
  });

  factory NumberStatistics.fromJson(Map<String, dynamic> json) =>
      NumberStatistics(
        number: _text(json['number']) ?? '',
        sampleStatus: _text(json['sampleStatus']) ?? 'NO_APPEARANCES_OBSERVED',
        appearancesObserved: _integer(json['appearancesObserved']),
        intervalsObserved: _integer(json['intervalsObserved']),
        verifiedIntervals: _integer(json['verifiedIntervals']),
        incompleteCoverageIntervals:
            _integer(json['incompleteCoverageIntervals']),
        minimumIntervalDays: json['minimumIntervalDays'] is num
            ? _integer(json['minimumIntervalDays'])
            : null,
        maximumIntervalDays: json['maximumIntervalDays'] is num
            ? _integer(json['maximumIntervalDays'])
            : null,
        averageIntervalDays: _decimal(json['averageIntervalDays']),
        medianIntervalDays: _decimal(json['medianIntervalDays']),
        latestIntervalDays: json['latestIntervalDays'] is num
            ? _integer(json['latestIntervalDays'])
            : null,
        lastAppearanceDate: _text(json['lastAppearanceDate']),
        daysSinceLastAppearance: json['daysSinceLastAppearance'] is num
            ? _integer(json['daysSinceLastAppearance'])
            : null,
      );
}

class NumberStatisticsResponse {
  final String asOfDate;
  final StatisticsQuality quality;
  final List<NumberStatistics> results;

  const NumberStatisticsResponse({
    required this.asOfDate,
    required this.quality,
    required this.results,
  });

  factory NumberStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      NumberStatisticsResponse(
        asOfDate: _text(json['asOfDate']) ?? '',
        quality: StatisticsQuality.fromJson(
            Map<String, dynamic>.from(json['quality'] as Map)),
        results: (json['results'] as List? ?? const [])
            .whereType<Map>()
            .map((item) =>
                NumberStatistics.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
}
