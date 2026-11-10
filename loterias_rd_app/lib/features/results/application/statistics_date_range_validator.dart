class StatisticsDateRangeValidation {
  final DateTime? from;
  final DateTime? to;
  final String? error;

  const StatisticsDateRangeValidation({
    required this.from,
    required this.to,
    required this.error,
  });

  bool get isValid => error == null && from != null && to != null;
}

class StatisticsDateRangeValidator {
  const StatisticsDateRangeValidator._();

  static StatisticsDateRangeValidation validate({
    required DateTime? from,
    required DateTime? to,
    required DateTime today,
    DateTime? coverageFrom,
    DateTime? coverageTo,
  }) {
    final normalizedFrom = from == null ? null : _dateOnly(from);
    final normalizedTo = to == null ? null : _dateOnly(to);
    final normalizedToday = _dateOnly(today);
    final normalizedCoverageFrom =
        coverageFrom == null ? null : _dateOnly(coverageFrom);
    final normalizedCoverageTo =
        coverageTo == null ? null : _dateOnly(coverageTo);

    String? error;
    if (normalizedFrom == null || normalizedTo == null) {
      error = 'Selecciona las fechas Desde y Hasta.';
    } else if (normalizedFrom.isAfter(normalizedTo)) {
      error = 'Desde no puede ser posterior a Hasta.';
    } else if (normalizedFrom.isAfter(normalizedToday) ||
        normalizedTo.isAfter(normalizedToday)) {
      error = 'El rango no puede incluir fechas futuras.';
    } else if ((normalizedCoverageFrom != null &&
            normalizedFrom.isBefore(normalizedCoverageFrom)) ||
        (normalizedCoverageTo != null &&
            normalizedTo.isAfter(normalizedCoverageTo))) {
      error = 'El rango debe estar dentro de la cobertura disponible.';
    }

    return StatisticsDateRangeValidation(
      from: normalizedFrom,
      to: normalizedTo,
      error: error,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
