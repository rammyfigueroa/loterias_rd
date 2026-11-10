import 'package:flutter/material.dart';

import '../../../app/app_features.dart';
import '../../../data/lottery_results_remote_source.dart';
import '../../../data/lottery_results_repository.dart';
import '../../../data/lottery_results_session.dart';
import '../../../data/sample_data.dart';
import '../../../domain/lottery_result.dart';
import '../../first_prize_statistics/data/first_prize_statistics_config.dart';
import '../../first_prize_statistics/presentation/first_prize_statistics_page.dart';
import '../../historical_relations/presentation/historical_relations_navigation.dart';
import '../application/lottery_catalog.dart';
import '../application/statistics_date_range_validator.dart';

enum StatsMode { calientes, frios, veces }

enum StatsPeriod { hoy, sieteDias, treintaDias, rango }

class StatsPage extends StatefulWidget {
  final bool historicalRelationsEnabled;
  final LotteryResultsSession? resultsSession;
  final DateTime? nowUtc;

  const StatsPage({
    super.key,
    this.historicalRelationsEnabled = AppFeatures.historicalRelationsEnabled,
    this.resultsSession,
    this.nowUtc,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final LotteryResultsSession _resultsSession;
  late final bool _ownsResultsSession;
  StatsMode _mode = StatsMode.frios;
  StatsPeriod _period = StatsPeriod.sieteDias;
  String? _selectedLottery;
  DateTime? _customFromDate;
  DateTime? _customToDate;
  DateTime? _appliedFromDate;
  DateTime? _appliedToDate;
  String? _rangeError;
  List<LotteryResult> _latestResults = const [];

  @override
  void initState() {
    super.initState();
    _ownsResultsSession = widget.resultsSession == null;
    _resultsSession = widget.resultsSession ??
        LotteryResultsSession(
          loader: LotteryResultsRepository(
            remoteSource: LotteryResultsRemoteSource(),
            sampleSource: SampleLotteryResultsSource(),
          ),
        );
    _resultsSession.addListener(_onResultsChanged);
    _loadResults();
  }

  @override
  void dispose() {
    _resultsSession.removeListener(_onResultsChanged);
    if (_ownsResultsSession) _resultsSession.dispose();
    super.dispose();
  }

  void _onResultsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadResults() async {
    try {
      await _resultsSession.load();
    } catch (_) {}
  }

  Future<void> _retryLoad() async {
    try {
      await _resultsSession.refresh();
    } catch (_) {}
  }

  String _normalizeNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.length == 1) return digits.padLeft(2, '0');
    if (digits.length == 2) return digits;
    return digits.substring(digits.length - 2);
  }

  List<String> _availableLotteries(List<LotteryResult> results) {
    final set = <String>{};
    for (final result in results) {
      if (result.lotteryName.trim().isNotEmpty) {
        set.add(result.lotteryName.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  DateTime _onlyDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  DateTime get _dominicanToday =>
      dominicanCalendarDate(widget.nowUtc ?? DateTime.now().toUtc());

  List<LotteryResult> _filterByPeriod(List<LotteryResult> results) {
    final today = _dominicanToday;
    DateTime? from;
    DateTime? to;

    switch (_period) {
      case StatsPeriod.hoy:
        from = today;
        to = today;
        break;
      case StatsPeriod.sieteDias:
        from = today.subtract(const Duration(days: 6));
        to = today;
        break;
      case StatsPeriod.treintaDias:
        from = today.subtract(const Duration(days: 29));
        to = today;
        break;
      case StatsPeriod.rango:
        if (_appliedFromDate == null || _appliedToDate == null) return const [];
        from = _onlyDate(_appliedFromDate!);
        to = _onlyDate(_appliedToDate!);
        break;
    }

    return results.where((result) {
      if (_selectedLottery != null && result.lotteryName != _selectedLottery) {
        return false;
      }
      final parsed = parseDrawDate(result.drawDate, now: today);
      if (parsed == null) return false;
      final date = _onlyDate(parsed);
      if (from != null && date.isBefore(from)) return false;
      if (to != null && date.isAfter(to)) return false;
      return true;
    }).toList();
  }

  String _formatDate(DateTime? date, String fallback) {
    if (date == null) return fallback;
    return formatCalendarDate(date);
  }

  Future<void> _pickCustomDate({required bool isFrom}) async {
    final today = _dominicanToday;
    final coverage = _availableCoverage(_latestResults);
    final coverageTo = coverage.to;
    final lastDate =
        coverageTo != null && coverageTo.isBefore(today) ? coverageTo : today;
    final coverageFrom = coverage.from ?? DateTime.utc(today.year - 5);
    final firstDate = coverageFrom.isAfter(lastDate) ? lastDate : coverageFrom;
    final initialDate = isFrom
        ? (_customFromDate ?? _customToDate ?? lastDate)
        : (_customToDate ?? _customFromDate ?? lastDate);
    final safeInitial = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate.isAfter(lastDate)
            ? lastDate
            : initialDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF003893),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _period = StatsPeriod.rango;
      if (isFrom) {
        _customFromDate = picked;
      } else {
        _customToDate = picked;
      }
      _rangeError = null;
    });
  }

  ({DateTime? from, DateTime? to}) _availableCoverage(
    List<LotteryResult> results,
  ) {
    final today = _dominicanToday;
    final dates = results
        .where((result) =>
            _selectedLottery == null || result.lotteryName == _selectedLottery)
        .map((result) => parseDrawDate(result.drawDate, now: today))
        .whereType<DateTime>()
        .map(_onlyDate)
        .toList()
      ..sort();
    return dates.isEmpty
        ? (from: null, to: null)
        : (from: dates.first, to: dates.last);
  }

  void _applyCustomRange() {
    final today = _dominicanToday;
    final coverage = _availableCoverage(_latestResults);
    final validation = StatisticsDateRangeValidator.validate(
      from: _customFromDate,
      to: _customToDate,
      today: today,
      coverageFrom: coverage.from,
      coverageTo: coverage.to,
    );
    setState(() {
      _rangeError = validation.error;
      if (validation.isValid) {
        _appliedFromDate = validation.from;
        _appliedToDate = validation.to;
      }
    });
  }

  List<_NumberStat> _buildStats(List<LotteryResult> results) {
    final stats = <String, _NumberStat>{};
    for (var i = 0; i < 100; i++) {
      final number = i.toString().padLeft(2, '0');
      stats[number] = _NumberStat(number: number);
    }

    for (var index = 0; index < results.length; index++) {
      final result = results[index];

      // Count every valid number returned by the API.
      // This makes statistics work correctly for Loto, Kino and special draws.
      for (final raw in result.numbers) {
        final number = _normalizeNumber(raw);
        if (number.isEmpty) continue;
        final stat = stats[number] ?? _NumberStat(number: number);
        stat.count += 1;
        stat.lotteries.add(result.lotteryName);
        if (stat.lastSeenIndex == null || index < stat.lastSeenIndex!) {
          stat.lastSeenIndex = index;
          stat.lastSeenDate = result.drawDate;
          stat.lastSeenLottery = result.lotteryName;
          stat.lastSeenDraw = result.drawName;
        }
        stats[number] = stat;
      }
    }

    final list = stats.values.toList();
    if (results.isEmpty) return const [];
    switch (_mode) {
      case StatsMode.calientes:
        list.sort((a, b) {
          final countCompare = b.count.compareTo(a.count);
          if (countCompare != 0) return countCompare;
          final aSeen = a.lastSeenIndex ?? 999999;
          final bSeen = b.lastSeenIndex ?? 999999;
          return aSeen.compareTo(bSeen);
        });
        return list.where((s) => s.count > 0).toList();
      case StatsMode.frios:
        list.sort((a, b) {
          final countCompare = a.count.compareTo(b.count);
          if (countCompare != 0) return countCompare;
          final aSeen = a.lastSeenIndex ?? 999999;
          final bSeen = b.lastSeenIndex ?? 999999;
          return bSeen.compareTo(aSeen);
        });
        return list;
      case StatsMode.veces:
        list.sort((a, b) {
          final countCompare = b.count.compareTo(a.count);
          if (countCompare != 0) return countCompare;
          return a.number.compareTo(b.number);
        });
        return list;
    }
  }

  String get _title {
    switch (_mode) {
      case StatsMode.calientes:
        return 'Números calientes';
      case StatsMode.frios:
        return 'Números fríos';
      case StatsMode.veces:
        return 'Veces que han salido';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case StatsMode.calientes:
        return 'Números que más se han repetido según el período seleccionado.';
      case StatsMode.frios:
        return 'Números con menor frecuencia según el período seleccionado.';
      case StatsMode.veces:
        return 'Conteo de apariciones por número en el período seleccionado.';
    }
  }

  String get _statsCardTitle {
    switch (_mode) {
      case StatsMode.calientes:
        return 'Más calientes';
      case StatsMode.frios:
        return 'Más fríos';
      case StatsMode.veces:
        return 'Más repetidos';
    }
  }

  String get _statsCardSubtitle {
    switch (_mode) {
      case StatsMode.calientes:
        return 'Los primeros 3 se muestran grandes. El resto queda debajo.';
      case StatsMode.frios:
        return 'Los primeros 3 son los de menor frecuencia en el período.';
      case StatsMode.veces:
        return 'Los primeros 3 son los que más apariciones registran.';
    }
  }

  Color get _accentColor {
    switch (_mode) {
      case StatsMode.calientes:
        return const Color(0xFFD90F2C);
      case StatsMode.frios:
        return const Color(0xFF003893);
      case StatsMode.veces:
        return const Color(0xFF003893);
    }
  }

  Color _modeBackground(StatsMode mode) {
    switch (mode) {
      case StatsMode.frios:
        return const Color(0xFF003893);
      case StatsMode.veces:
        return Colors.white;
      case StatsMode.calientes:
        return const Color(0xFFD90F2C);
    }
  }

  Color _modeForeground(StatsMode mode) {
    switch (mode) {
      case StatsMode.veces:
        return const Color(0xFF003893);
      case StatsMode.frios:
      case StatsMode.calientes:
        return Colors.white;
    }
  }

  IconData _modeIcon(StatsMode mode) {
    switch (mode) {
      case StatsMode.frios:
        return Icons.ac_unit;
      case StatsMode.veces:
        return Icons.analytics_outlined;
      case StatsMode.calientes:
        return Icons.local_fire_department;
    }
  }

  Widget _modeChip(String label, StatsMode mode) {
    final selected = _mode == mode;
    final background = _modeBackground(mode);
    final foreground = _modeForeground(mode);
    final isWhite = mode == StatsMode.veces;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 52,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.white
                : (isWhite ? const Color(0xFFE5E7EB) : Colors.white24),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: selected ? 12 : 7,
              offset: Offset(0, selected ? 5 : 3),
              color: selected ? Colors.black26 : Colors.black12,
            ),
          ],
        ),
        child: Semantics(
          button: true,
          selected: selected,
          label: 'Estadística $label',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _mode = mode),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _modeIcon(mode),
                    size: selected ? 18 : 16,
                    color: foreground,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w800,
                        fontSize: selected ? 12.5 : 12,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodChip(String label, StatsPeriod period) {
    final selected = _period == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.white,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF003893) : const Color(0xFFE5E7EB),
          width: selected ? 1.5 : 1,
        ),
        labelStyle: TextStyle(
          color: const Color(0xFF003893),
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          fontSize: 12,
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        onSelected: (_) {
          setState(() {
            _period = period;
            if (period != StatsPeriod.rango) _rangeError = null;
          });
        },
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _periodChip('Hoy', StatsPeriod.hoy),
                _periodChip('7 días', StatsPeriod.sieteDias),
                _periodChip('30 días', StatsPeriod.treintaDias),
                _periodChip('Rango', StatsPeriod.rango),
              ],
            ),
          ),
          if (_period == StatsPeriod.rango) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, 4),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickCustomDate(isFrom: true),
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Desde: ${_formatDate(_customFromDate, '--/--/----')}',
                                style: const TextStyle(
                                  color: Color(0xFF003893),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickCustomDate(isFrom: false),
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Hasta: ${_formatDate(_customToDate, '--/--/----')}',
                                style: const TextStyle(
                                  color: Color(0xFF003893),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_customFromDate != null || _customToDate != null)
                        IconButton(
                          tooltip: 'Limpiar rango',
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF003893),
                          ),
                          onPressed: () {
                            setState(() {
                              _customFromDate = null;
                              _customToDate = null;
                              _appliedFromDate = null;
                              _appliedToDate = null;
                              _rangeError = null;
                            });
                          },
                        ),
                    ],
                  ),
                  if (_rangeError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _rangeError!,
                      key: const Key('local-statistics-range-error'),
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      key: const Key('apply-local-statistics-range'),
                      onPressed: _applyCustomRange,
                      icon: const Icon(Icons.check, size: 17),
                      label: const Text('Aplicar fechas'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLotteryFilter(List<LotteryResult> results) {
    final lotteries = _availableLotteries(results);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 4),
            color: Colors.black12,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedLottery,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF003893)),
          hint: const Text(
            'Todas las loterías',
            style: TextStyle(
              color: Color(0xFF003893),
              fontWeight: FontWeight.w700,
            ),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todas las loterías'),
            ),
            ...lotteries.map(
              (lottery) => DropdownMenuItem<String?>(
                value: lottery,
                child: Text(lottery),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedLottery = value;
              if (_period == StatsPeriod.rango) {
                _appliedFromDate = null;
                _appliedToDate = null;
                _rangeError = 'Aplica nuevamente el rango para esta lotería.';
              }
            });
          },
        ),
      ),
    );
  }

  String get _periodDescription {
    switch (_period) {
      case StatsPeriod.hoy:
        return 'Hoy (hora dominicana)';
      case StatsPeriod.sieteDias:
        return 'Últimos 7 días';
      case StatsPeriod.treintaDias:
        return 'Últimos 30 días';
      case StatsPeriod.rango:
        if (_appliedFromDate == null || _appliedToDate == null) {
          return 'Rango pendiente de aplicar';
        }
        return '${formatCalendarDate(_appliedFromDate!)} al ${formatCalendarDate(_appliedToDate!)}';
    }
  }

  Widget _buildSampleSummary(
    List<LotteryResult> allResults,
    List<LotteryResult> filteredResults,
  ) {
    final coverage = _availableCoverage(allResults);
    final appearances = filteredResults.fold<int>(
      0,
      (total, result) =>
          total +
          result.numbers
              .where((number) => _normalizeNumber(number).isNotEmpty)
              .length,
    );
    final coverageText = coverage.from == null || coverage.to == null
        ? 'Cobertura no disponible'
        : 'Cobertura: ${formatCalendarDate(coverage.from!)} al ${formatCalendarDate(coverage.to!)}';
    final drawCount = filteredResults.length;
    final drawLabel =
        drawCount == 1 ? 'sorteo analizado' : 'sorteos analizados';
    final appearanceLabel = appearances == 1 ? 'aparición' : 'apariciones';
    return Container(
      key: const Key('statistics-sample-summary'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$drawCount $drawLabel · $appearances $appearanceLabel',
            key: const Key('statistics-sample-size'),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Período: $_periodDescription',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            coverageText,
            key: const Key('statistics-coverage'),
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Resumen histórico descriptivo; no predice resultados futuros.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    offset: Offset(0, 3),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Icon(
                _mode == StatsMode.frios
                    ? Icons.ac_unit
                    : _mode == StatsMode.calientes
                        ? Icons.local_fire_department
                        : Icons.analytics,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Semantics(
      liveRegion: true,
      label: 'Cargando estadísticas',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.16),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Calculando estadísticas...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Estamos revisando los resultados del período seleccionado.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Error al cargar estadísticas',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 6),
                  color: Colors.black12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x14003893),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFF003893),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No pudimos cargar las estadísticas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Verifica tu conexión o intenta nuevamente en unos segundos.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retryLoad,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003893),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsList(List<_NumberStat> stats) {
    if (stats.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 150;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: compact
                  ? Text(
                      'No hay datos para el rango aplicado.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.24),
                            ),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No hay datos suficientes para calcular estadísticas.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Prueba cambiar el período o seleccionar otra lotería.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          );
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        _StatsNumbersCard(
          title: _statsCardTitle,
          subtitle: _statsCardSubtitle,
          stats: stats,
          accentColor: _accentColor,
          mode: _mode,
        ),
      ],
    );
  }

  Widget _buildFirstPrizeStatisticsEntry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Card(
        child: ListTile(
          key: const Key('first-prize-statistics-entry'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE7F0FF),
            foregroundColor: Color(0xFF003893),
            child: Icon(Icons.analytics_outlined),
          ),
          title: const Text(
            'Coincidencias de Primera',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: const Text('Lotería Nacional y Gana Más · primer premio'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FirstPrizeStatisticsPage()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final response = _resultsSession.response;
    final results = response == null
        ? const <LotteryResult>[]
        : (List<LotteryResult>.from(response.results)
          ..sort((a, b) => b.drawDate.compareTo(a.drawDate)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003893), Color(0xFF004fcf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003893), Color(0xFF004fcf), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.32, 1.0],
          ),
        ),
        child: response == null
            ? (_resultsSession.state == LotteryResultsSessionState.error
                ? _buildErrorState()
                : _buildLoadingState())
            : _buildLoadedStatistics(results),
      ),
    );
  }

  Widget _buildLoadedStatistics(List<LotteryResult> results) {
    _latestResults = results;
    final filteredResults = _filterByPeriod(results);
    final stats = _buildStats(filteredResults);
    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_resultsSession.isRefreshing)
          const LinearProgressIndicator(minHeight: 3),
        if (_resultsSession.error != null)
          MaterialBanner(
            content: const Text(
              'No se pudo actualizar. Las estadísticas usan los resultados anteriores.',
            ),
            actions: [
              TextButton(
                onPressed: _retryLoad,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        _buildHeader(),
        if (FirstPrizeStatisticsConfig.available)
          _buildFirstPrizeStatisticsEntry(),
        if (widget.historicalRelationsEnabled)
          const HistoricalRelationsEntry(enabled: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _modeChip('Fríos', StatsMode.frios),
              const SizedBox(width: 8),
              _modeChip('Veces', StatsMode.veces),
              const SizedBox(width: 8),
              _modeChip('Calientes', StatsMode.calientes),
            ],
          ),
        ),
        _buildPeriodFilter(),
        _buildLotteryFilter(results),
        _buildSampleSummary(results, filteredResults),
      ],
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final constrained = constraints.maxHeight < 720 || textScale > 1.3;
        return Column(
          children: [
            if (constrained)
              Flexible(
                child: SingleChildScrollView(
                  key: const Key('statistics-controls-scroll'),
                  child: controls,
                ),
              )
            else
              controls,
            Expanded(child: _buildStatsList(stats)),
          ],
        );
      },
    );
  }
}

class _NumberStat {
  final String number;
  int count;
  int? lastSeenIndex;
  String? lastSeenDate;
  String? lastSeenLottery;
  String? lastSeenDraw;
  final Set<String> lotteries;

  _NumberStat({
    required this.number,
    this.count = 0,
    this.lastSeenIndex,
    this.lastSeenDate,
    this.lastSeenLottery,
    this.lastSeenDraw,
    Set<String>? lotteries,
  }) : lotteries = lotteries ?? <String>{};
}

class _StatsNumbersCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_NumberStat> stats;
  final Color accentColor;
  final StatsMode mode;

  const _StatsNumbersCard({
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.accentColor,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final mainStats = stats.take(3).toList();
    final extraStats =
        stats.length > 3 ? stats.skip(3).toList() : <_NumberStat>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Colors.black26,
          ),
        ],
      ),
      child: Column(
        children: [
          _StatsCardHeader(
            title: title,
            subtitle: subtitle,
            accentColor: accentColor,
            mode: mode,
            total: stats.length,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final stat = index < mainStats.length
                  ? mainStats[index]
                  : _NumberStat(number: '--');
              return _StatBall(
                stat: stat,
                rank: index + 1,
                mode: mode,
                accentColor: accentColor,
                size: 78,
                isMain: true,
              );
            }),
          ),
          if (extraStats.isNotEmpty) ...[
            const SizedBox(height: 18),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 11,
              runSpacing: 12,
              children: extraStats.map((stat) {
                return _StatBall(
                  stat: stat,
                  rank: null,
                  mode: mode,
                  accentColor: accentColor,
                  size: 48,
                  isMain: false,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsCardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final StatsMode mode;
  final int total;

  const _StatsCardHeader({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.mode,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final icon = mode == StatsMode.frios
        ? Icons.ac_unit
        : mode == StatsMode.calientes
            ? Icons.local_fire_department
            : Icons.analytics_outlined;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                blurRadius: 7,
                offset: Offset(0, 3),
                color: Colors.black26,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$total',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBall extends StatelessWidget {
  final _NumberStat stat;
  final int? rank;
  final StatsMode mode;
  final Color accentColor;
  final double size;
  final bool isMain;

  const _StatBall({
    required this.stat,
    required this.rank,
    required this.mode,
    required this.accentColor,
    required this.size,
    required this.isMain,
  });

  @override
  Widget build(BuildContext context) {
    final ballColor = _ballColor;
    final textColor = _textColor;
    final badgeColor = stat.count == 0
        ? const Color(0xFF94A3B8)
        : mode == StatsMode.calientes
            ? const Color(0xFFD90F2C)
            : const Color(0xFF003893);

    return SizedBox(
      width: isMain ? size + 10 : size + 6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ballColor,
                  border: Border.all(
                    color: _needsBorder
                        ? Colors.grey.shade300
                        : Colors.white.withOpacity(0.78),
                    width: isMain ? 2.4 : 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 4),
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: Text(
                  stat.number,
                  style: TextStyle(
                    color: textColor,
                    fontSize: size * 0.40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Positioned(
                right: isMain ? -4 : -6,
                top: isMain ? -5 : -7,
                child: _CountBadge(
                  count: stat.count,
                  color: badgeColor,
                  isMain: isMain,
                ),
              ),
            ],
          ),
          if (isMain) ...[
            const SizedBox(height: 8),
            Text(
              rank == null ? '' : '#$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _needsBorder {
    return mode == StatsMode.veces ||
        !isMain ||
        _ballColor == const Color(0xFFF3F4F6);
  }

  Color get _ballColor {
    if (!isMain) {
      if (mode == StatsMode.calientes) return const Color(0xFFFFEEF2);
      return const Color(0xFFEEF2FF);
    }

    if (mode == StatsMode.calientes) {
      return const Color(0xFFD90F2C);
    }

    if (mode == StatsMode.frios) {
      return const Color(0xFF003893);
    }

    // Veces: keep a premium blue/white/red rhythm for the three main numbers.
    if (rank == 1) return const Color(0xFF003893);
    if (rank == 2) return const Color(0xFFF3F4F6);
    return const Color(0xFFD90F2C);
  }

  Color get _textColor {
    if (!isMain) {
      return mode == StatsMode.calientes
          ? const Color(0xFFD90F2C)
          : const Color(0xFF003893);
    }

    if (mode == StatsMode.veces && rank == 2) {
      return const Color(0xFF0F172A);
    }

    return Colors.white;
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final bool isMain;

  const _CountBadge({
    required this.count,
    required this.color,
    required this.isMain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: isMain ? 24 : 22,
        minHeight: isMain ? 24 : 22,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            offset: Offset(0, 2),
            color: Colors.black12,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${count}x',
          style: TextStyle(
            color: color,
            fontSize: isMain ? 10.5 : 9.5,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
