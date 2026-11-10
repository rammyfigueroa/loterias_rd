import 'package:flutter/material.dart';

import '../../results/application/lottery_catalog.dart';
import '../application/first_prize_statistics_controller.dart';
import '../application/statistics_comparison.dart';
import '../data/first_prize_statistics_config.dart';
import '../data/first_prize_statistics_remote_source.dart';
import '../data/first_prize_statistics_repository.dart';
import '../domain/first_prize_statistics.dart';

const _blue = Color(0xFF003893);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _background = Color(0xFFF4F7FB);
const _warning = Color(0xFF9A6700);

String statisticsDate(String? value) {
  if (value == null || value.isEmpty) return 'No disponible';
  final date = DateTime.tryParse(value);
  return date == null ? value : formatCalendarDate(date);
}

class FirstPrizeStatisticsPage extends StatefulWidget {
  final FirstPrizeStatisticsRepository? repository;
  final DateTime? nowUtc;
  final List<StatisticsDrawOption> draws;

  const FirstPrizeStatisticsPage({
    super.key,
    this.repository,
    this.nowUtc,
    this.draws = StatisticsSeries.draws,
  });

  @override
  State<FirstPrizeStatisticsPage> createState() =>
      _FirstPrizeStatisticsPageState();
}

class _FirstPrizeStatisticsPageState extends State<FirstPrizeStatisticsPage> {
  late final FirstPrizeStatisticsController controller;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository ??
        RemoteFirstPrizeStatisticsRepository(
          FirstPrizeStatisticsRemoteSource(
              baseUrl: FirstPrizeStatisticsConfig.apiBaseUrl),
        );
    controller = FirstPrizeStatisticsController(
      repository,
      draws: widget.draws,
    )..addListener(_refresh);
    controller.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _blue,
          title: const Text('Coincidencias de Primera'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFBFD7FF),
            isScrollable: true,
            tabs: [
              Tab(text: 'Coincidencias'),
              Tab(text: 'Números'),
              Tab(text: 'Situación actual'),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final constrained = constraints.maxHeight < 650 || textScale > 1.3;
            final header = _SeriesHeader(controller: controller);
            return Column(
              children: [
                if (constrained)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .58,
                    ),
                    child: SingleChildScrollView(
                      key: const Key('first-prize-header-scroll'),
                      child: header,
                    ),
                  )
                else
                  header,
                Expanded(
                  child: TabBarView(
                    children: [
                      _CoincidencesTab(controller: controller),
                      _NumbersTab(controller: controller),
                      _CurrentSituationTab(
                          controller: controller, nowUtc: widget.nowUtc),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SeriesHeader extends StatelessWidget {
  final FirstPrizeStatisticsController controller;
  const _SeriesHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _blue,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análisis histórico de apariciones en primer premio.',
            style: TextStyle(
                color: Color(0xFFD9E8FF), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _DrawSelector(controller: controller),
          const SizedBox(height: 10),
          _DateRangeSelector(controller: controller),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _HeaderChip(
                Icons.account_balance_outlined,
                StatisticsSeries.operatorName,
              ),
              _HeaderChip(
                Icons.casino_outlined,
                controller.mode == StatisticsMode.both
                    ? 'Lotería Nacional + Gana Más'
                    : controller.selectedDraw.displayName,
              ),
              const _HeaderChip(
                Icons.looks_one_outlined,
                StatisticsSeries.prizeName,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  final FirstPrizeStatisticsController controller;
  const _DateRangeSelector({required this.controller});

  Future<void> _pick(BuildContext context, bool from) async {
    final available = controller.availableRange;
    if (available.first == null || available.last == null) return;
    final current = from
        ? controller.pendingFrom ??
            controller.appliedRange?.from ??
            available.first!
        : controller.pendingTo ??
            controller.appliedRange?.to ??
            available.last!;
    final selected = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: current.isBefore(available.first!)
          ? available.first!
          : current.isAfter(available.last!)
              ? available.last!
              : current,
      firstDate: available.first!,
      lastDate: available.last!,
      helpText: from ? 'Seleccionar fecha desde' : 'Seleccionar fecha hasta',
    );
    if (selected != null) {
      from
          ? controller.setPendingFrom(selected)
          : controller.setPendingTo(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = controller.availableRange;
    final from = controller.pendingFrom ??
        controller.appliedRange?.from ??
        available.first;
    final to =
        controller.pendingTo ?? controller.appliedRange?.to ?? available.last;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Período de análisis',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          final controls = [
            _DateButton(
                key: const Key('date-from'),
                label: 'Desde',
                date: from,
                onTap: () => _pick(context, true)),
            _DateButton(
                key: const Key('date-to'),
                label: 'Hasta',
                date: to,
                onTap: () => _pick(context, false)),
          ];
          return narrow
              ? Column(children: [
                  controls[0],
                  const SizedBox(height: 8),
                  controls[1]
                ])
              : Row(children: [
                  Expanded(child: controls[0]),
                  const SizedBox(width: 8),
                  Expanded(child: controls[1])
                ]);
        }),
        if (controller.rangeError != null) ...[
          const SizedBox(height: 8),
          Text(controller.rangeError!,
              key: const Key('range-error'),
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            key: const Key('full-history'),
            onPressed: controller.useFullHistory,
            icon: const Icon(Icons.history),
            label: const Text('Todo el historial'),
          ),
          FilledButton.icon(
            key: const Key('apply-dates'),
            onPressed:
                available.first == null ? null : controller.applyPendingRange,
            icon: const Icon(Icons.check),
            label: const Text('Aplicar fechas'),
          ),
        ]),
        if (controller.appliedRange != null)
          const Text('Rango personalizado activo',
              style: TextStyle(
                  color: Color(0xFF15803D), fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateButton(
      {super.key,
      required this.label,
      required this.date,
      required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: date == null ? null : onTap,
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: ${date == null ? 'Cargando…' : formatCalendarDate(date!)}',
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
}

class _DrawSelector extends StatelessWidget {
  final FirstPrizeStatisticsController controller;
  const _DrawSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final unavailable = controller.draws.where((draw) => !draw.available);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in const [
              (StatisticsMode.national, 'Lotería Nacional'),
              (StatisticsMode.ganaMas, 'Gana Más'),
              (StatisticsMode.both, 'Ambas'),
            ])
              ChoiceChip(
                key: Key('mode-${option.$1.name}'),
                avatar: Icon(
                    option.$1 == StatisticsMode.both
                        ? Icons.compare_arrows
                        : Icons.casino_outlined,
                    size: 17),
                label: Text(option.$2),
                selected: option.$1 == controller.mode,
                onSelected: (selected) {
                  if (selected) controller.selectMode(option.$1);
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .12),
                disabledColor: Colors.white.withValues(alpha: .06),
                labelStyle: TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: option.$1 == controller.mode
                      ? Colors.white
                      : Colors.white24,
                ),
              ),
          ],
        ),
        if (unavailable.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            unavailable
                .map((draw) =>
                    '${draw.displayName}: ${draw.unavailableReason ?? 'No disponible'}')
                .join(' · '),
            key: const Key('draw-unavailable-reason'),
            style: const TextStyle(
              color: Color(0xFFBFD0EA),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      );
}

class _CoincidencesTab extends StatelessWidget {
  final FirstPrizeStatisticsController controller;
  const _CoincidencesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadIntervals,
      child: ListView(
        key: const Key('coincidences-list'),
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'verified', label: Text('Verificados')),
                ButtonSegment(value: 'incomplete', label: Text('Incompletos')),
                ButtonSegment(value: 'all', label: Text('Todos')),
              ],
              selected: {controller.coverage},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  controller.loadIntervals(value.first),
            ),
          ),
          if (controller.coverage != 'verified') ...[
            const SizedBox(height: 12),
            const _WarningCard(
              text:
                  'Algunos períodos contienen fechas sin verificar. Los intervalos podrían no representar apariciones consecutivas reales.',
            ),
          ],
          const SizedBox(height: 14),
          _StateBody(
            state: controller.intervalState,
            error: controller.intervalError,
            onRetry: controller.loadIntervals,
            emptyText: 'No hay intervalos para este filtro.',
            child: controller.mode == StatisticsMode.both
                ? _CombinedCoincidences(controller: controller)
                : Column(children: [
                    for (var index = 0;
                        index < (controller.intervals?.results.length ?? 0);
                        index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _IntervalCard(
                          rank: index + 1,
                          interval: controller.intervals!.results[index],
                          coverage: controller.coverage,
                          repository: controller.repository,
                          draw: controller.selectedDraw,
                          range: controller.appliedRange,
                        ),
                      ),
                  ]),
          ),
          if (controller.mode == StatisticsMode.both &&
              controller.intervalsByDraw.length == 2) ...[
            const SizedBox(height: 4),
            _CoverageCard(
                controller
                    .intervalsByDraw[StatisticsSeries.national.drawId]!.quality,
                title: 'Cobertura · Lotería Nacional'),
            _CoverageCard(
                controller
                    .intervalsByDraw[StatisticsSeries.ganaMas.drawId]!.quality,
                title: 'Cobertura · Gana Más'),
            const _Disclaimer(),
          ] else if (controller.intervals != null) ...[
            const SizedBox(height: 4),
            _CoverageCard(controller.intervals!.quality),
            const SizedBox(height: 12),
            const _Disclaimer(),
          ],
        ],
      ),
    );
  }
}

class _CombinedCoincidences extends StatefulWidget {
  final FirstPrizeStatisticsController controller;
  const _CombinedCoincidences({required this.controller});

  @override
  State<_CombinedCoincidences> createState() => _CombinedCoincidencesState();
}

class _CombinedCoincidencesState extends State<_CombinedCoincidences> {
  bool shared = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Ranking combinado')),
            ButtonSegment(value: true, label: Text('Compartidas')),
          ],
          selected: {shared},
          showSelectedIcon: false,
          onSelectionChanged: (value) => setState(() => shared = value.first),
        ),
      ),
      const SizedBox(height: 12),
      if (!shared)
        for (var index = 0;
            index < controller.combinedIntervals.length;
            index++)
          _CombinedIntervalCard(
            rank: index + 1,
            item: controller.combinedIntervals[index],
            controller: controller,
          )
      else if (controller.sharedMatches.isEmpty)
        const _InfoMessage('No hay coincidencias compartidas para este filtro.')
      else
        for (final item in controller.sharedMatches)
          _SharedMatchCard(item: item, controller: controller),
    ]);
  }
}

class _CombinedIntervalCard extends StatelessWidget {
  final int rank;
  final CombinedIntervalRanking item;
  final FirstPrizeStatisticsController controller;
  const _CombinedIntervalCard(
      {required this.rank, required this.item, required this.controller});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          key: Key('combined-interval-${item.days}'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CombinedIntervalDetailPage(
              days: item.days,
              coverage: controller.coverage,
              repository: controller.repository,
              range: controller.appliedRange,
            ),
          )),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$rank · ${item.days} DÍAS',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              _SeriesSummary('Lotería Nacional', item.national),
              _SeriesSummary('Gana Más', item.ganaMas),
              const Divider(),
              Text(
                  '${item.totalNumberDrawMatches} coincidencias por número y sorteo · ${item.totalRepetitions} repeticiones',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}

class _SeriesSummary extends StatelessWidget {
  final String label;
  final IntervalRanking? item;
  const _SeriesSummary(this.label, this.item);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
            '$label: ${item?.distinctNumbers ?? 0} números · ${item?.totalRepetitions ?? 0} repeticiones'),
      );
}

class _SharedMatchCard extends StatelessWidget {
  final SharedIntervalMatch item;
  final FirstPrizeStatisticsController controller;
  const _SharedMatchCard({required this.item, required this.controller});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          key: Key('shared-${item.days}'),
          title: Text('${item.days} DÍAS · ${item.numbers.length} compartidos',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.numbers.map((n) => _NumberBall(n)).toList()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CombinedIntervalDetailPage(
                days: item.days,
                coverage: controller.coverage,
                repository: controller.repository,
                range: controller.appliedRange),
          )),
        ),
      );
}

class _IntervalCard extends StatelessWidget {
  final int rank;
  final IntervalRanking interval;
  final String coverage;
  final FirstPrizeStatisticsRepository repository;
  final StatisticsDrawOption draw;
  final StatisticsDateRange? range;

  const _IntervalCard({
    required this.rank,
    required this.interval,
    required this.coverage,
    required this.repository,
    required this.draw,
    this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: Key('interval-${interval.days}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => IntervalDetailPage(
            days: interval.days,
            coverage: coverage,
            repository: repository,
            draw: draw,
            range: range,
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE7F0FF),
              foregroundColor: _blue,
              child: Text('$rank',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${interval.days} DÍAS',
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      '${interval.distinctNumbers} números diferentes · ${interval.totalRepetitions} repeticiones',
                      style: const TextStyle(
                          color: _muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: interval.numbers
                          .map((number) => _NumberBall(number))
                          .toList()),
                ])),
            const Icon(Icons.chevron_right, color: _muted),
          ]),
        ),
      ),
    );
  }
}

class IntervalDetailPage extends StatefulWidget {
  final int days;
  final String coverage;
  final FirstPrizeStatisticsRepository repository;
  final StatisticsDrawOption draw;
  final StatisticsDateRange? range;

  const IntervalDetailPage({
    super.key,
    required this.days,
    required this.coverage,
    required this.repository,
    required this.draw,
    this.range,
  });

  @override
  State<IntervalDetailPage> createState() => _IntervalDetailPageState();
}

class CombinedIntervalDetailPage extends StatelessWidget {
  final int days;
  final String coverage;
  final FirstPrizeStatisticsRepository repository;
  final StatisticsDateRange? range;

  const CombinedIntervalDetailPage({
    super.key,
    required this.days,
    required this.coverage,
    required this.repository,
    this.range,
  });

  @override
  Widget build(BuildContext context) {
    final future = Future.wait([
      repository.getIntervalDetail(StatisticsSeries.national, days, coverage,
          range: range),
      repository.getIntervalDetail(StatisticsSeries.ganaMas, days, coverage,
          range: range),
    ]);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: Text('$days días · Ambas')),
      body: FutureBuilder<List<IntervalDetail>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _FullError(
              onRetry: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => CombinedIntervalDetailPage(
                          days: days,
                          coverage: coverage,
                          repository: repository,
                          range: range,
                        )),
              ),
            );
          }
          final details = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SeriesDetailSection('Lotería Nacional', details[0]),
              const SizedBox(height: 12),
              _SeriesDetailSection('Gana Más', details[1]),
              const SizedBox(height: 12),
              const _Disclaimer(),
            ],
          );
        },
      ),
    );
  }
}

class _SeriesDetailSection extends StatelessWidget {
  final String title;
  final IntervalDetail detail;
  const _SeriesDetailSection(this.title, this.detail);

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
                '${detail.distinctNumbers} números · ${detail.totalRepetitions} repeticiones'),
            const Divider(),
            if (detail.occurrences.isEmpty)
              const Text('Sin apariciones para este filtro.'),
            for (final occurrence in detail.occurrences)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  _NumberBall(occurrence.number),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          '${statisticsDate(occurrence.startDate)} → ${statisticsDate(occurrence.endDate)}\n${occurrence.coverageStatus == 'VERIFIED' ? 'Verificado' : 'Cobertura incompleta'}')),
                ]),
              ),
          ]),
        ),
      );
}

class _IntervalDetailPageState extends State<IntervalDetailPage> {
  late Future<IntervalDetail> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.getIntervalDetail(
      widget.draw,
      widget.days,
      widget.coverage,
      range: widget.range,
    );
  }

  void retry() => setState(() {
        future = widget.repository.getIntervalDetail(
          widget.draw,
          widget.days,
          widget.coverage,
          range: widget.range,
        );
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: Text('${widget.days} días')),
      body: FutureBuilder<IntervalDetail>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _FullError(onRetry: retry);
          final detail = snapshot.data!;
          if (detail.occurrences.isEmpty)
            return const Center(child: Text('No hay detalles disponibles.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                  '${detail.distinctNumbers} números distintos · ${detail.totalRepetitions} repeticiones',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              for (final item in detail.occurrences)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NumberBall(item.number, large: true),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    'Primera aparición: ${statisticsDate(item.startDate)}'),
                                const SizedBox(height: 4),
                                Text(
                                    'Siguiente aparición: ${statisticsDate(item.endDate)}'),
                                const SizedBox(height: 4),
                                Text('Intervalo: ${item.days} días',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text(
                                    item.coverageStatus == 'VERIFIED'
                                        ? 'Cobertura verificada'
                                        : 'Cobertura incompleta',
                                    style: TextStyle(
                                        color: item.coverageStatus == 'VERIFIED'
                                            ? const Color(0xFF15803D)
                                            : _warning,
                                        fontWeight: FontWeight.w800)),
                              ])),
                        ]),
                  ),
                ),
              const _Disclaimer(),
            ],
          );
        },
      ),
    );
  }
}

class _NumbersTab extends StatelessWidget {
  final FirstPrizeStatisticsController controller;
  const _NumbersTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final combined = controller.mode == StatisticsMode.both;
    final source = combined
        ? controller.numbersFor(StatisticsSeries.national)
        : controller.numbers;
    return _StateBody(
      state: controller.numberState,
      error: controller.numberError,
      onRetry: controller.loadNumbers,
      emptyText: 'No hay estadísticas por número.',
      child: GridView.builder(
        key: const Key('numbers-grid'),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 74,
          mainAxisExtent: 58,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: source?.results.length ?? 0,
        itemBuilder: (context, index) {
          final item = source!.results[index];
          return InkWell(
            key: Key('number-${item.number}'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => combined
                  ? _CombinedNumberDetailSheet(
                      number: item.number,
                      national: controller
                          .numbersFor(StatisticsSeries.national)!
                          .results[index],
                      ganaMas: controller
                          .numbersFor(StatisticsSeries.ganaMas)!
                          .results[index],
                      customRange: controller.appliedRange != null,
                    )
                  : _NumberDetailSheet(item,
                      customRange: controller.appliedRange != null),
            ),
            child: Ink(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDCE4EF))),
              child: Center(
                  child: Text(item.number,
                      style: const TextStyle(
                          color: _blue,
                          fontSize: 19,
                          fontWeight: FontWeight.w900))),
            ),
          );
        },
      ),
    );
  }
}

class _CombinedNumberDetailSheet extends StatelessWidget {
  final String number;
  final NumberStatistics national;
  final NumberStatistics ganaMas;
  final bool customRange;
  const _CombinedNumberDetailSheet(
      {required this.number,
      required this.national,
      required this.ganaMas,
      required this.customRange});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _NumberBall(number, large: true),
              const SizedBox(width: 12),
              const Text('Comparación por número',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))
            ]),
            const SizedBox(height: 16),
            _NumberSeriesMetrics('Lotería Nacional', national,
                customRange: customRange),
            _NumberSeriesMetrics('Gana Más', ganaMas, customRange: customRange),
            const _Disclaimer(),
          ]),
        ),
      );
}

class _NumberSeriesMetrics extends StatelessWidget {
  final String title;
  final NumberStatistics item;
  final bool customRange;
  const _NumberSeriesMetrics(this.title, this.item,
      {required this.customRange});
  String value(num? number) => number == null
      ? 'No disponible'
      : '${number.toString().replaceFirst(RegExp(r'\.0$'), '')} días';
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const Divider(),
            _MetricRow('Apariciones', '${item.appearancesObserved}'),
            _MetricRow(
                customRange
                    ? 'Última aparición dentro del período'
                    : 'Última aparición',
                statisticsDate(item.lastAppearanceDate)),
            _MetricRow('Intervalos', '${item.intervalsObserved}'),
            _MetricRow('Promedio', value(item.averageIntervalDays)),
            _MetricRow('Mediana', value(item.medianIntervalDays)),
          ]),
        ),
      );
}

class _NumberDetailSheet extends StatelessWidget {
  final NumberStatistics item;
  final bool customRange;
  const _NumberDetailSheet(this.item, {required this.customRange});

  String _days(num? value) => value == null
      ? 'No disponible'
      : '${value.toString().replaceFirst(RegExp(r'\.0$'), '')} días';

  @override
  Widget build(BuildContext context) {
    final insufficient = item.sampleStatus == 'SINGLE_APPEARANCE';
    final absent = item.sampleStatus == 'NO_APPEARANCES_OBSERVED';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                _NumberBall(item.number, large: true),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Estadísticas individuales',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)))
              ]),
              const SizedBox(height: 16),
              if (absent)
                const _InfoMessage('Sin apariciones en el período disponible.')
              else if (insufficient)
                const _InfoMessage(
                    'Historial insuficiente para calcular intervalos.')
              else ...[
                _MetricRow(
                    customRange
                        ? 'Última aparición dentro del período'
                        : 'Última aparición',
                    statisticsDate(item.lastAppearanceDate)),
                _MetricRow(
                    customRange
                        ? 'Días hasta el final del período'
                        : 'Días desde última aparición',
                    _days(item.daysSinceLastAppearance)),
                _MetricRow('Apariciones', '${item.appearancesObserved}'),
                _MetricRow('Intervalos', '${item.intervalsObserved}'),
                _MetricRow('Intervalo mínimo', _days(item.minimumIntervalDays)),
                _MetricRow('Intervalo máximo', _days(item.maximumIntervalDays)),
                _MetricRow('Promedio', _days(item.averageIntervalDays)),
                _MetricRow('Mediana', _days(item.medianIntervalDays)),
                _MetricRow('Último intervalo', _days(item.latestIntervalDays)),
              ],
              const SizedBox(height: 12),
              const _Disclaimer(),
            ])),
      ),
    );
  }
}

class _CurrentSituationTab extends StatelessWidget {
  final FirstPrizeStatisticsController controller;
  final DateTime? nowUtc;
  const _CurrentSituationTab({required this.controller, required this.nowUtc});

  @override
  Widget build(BuildContext context) {
    if (controller.mode == StatisticsMode.both) {
      return _CombinedCurrentSituation(controller: controller, nowUtc: nowUtc);
    }
    final response = controller.numbers;
    final today = dominicanCalendarDate((nowUtc ?? DateTime.now()).toUtc());
    final asOf = response == null ? null : DateTime.tryParse(response.asOfDate);
    final staleDays = asOf == null
        ? null
        : today
            .difference(DateTime.utc(asOf.year, asOf.month, asOf.day))
            .inDays;
    final customRange = controller.appliedRange != null;
    return _StateBody(
      state: controller.numberState,
      error: controller.numberError,
      onRetry: controller.loadNumbers,
      emptyText: 'No hay información de situación actual.',
      child: ListView(
        key: const Key('current-situation-list'),
        padding: const EdgeInsets.all(16),
        children: [
          if (!customRange && staleDays != null && staleDays > 0)
            _WarningCard(
                text:
                    'El historial está desactualizado por $staleDays día${staleDays == 1 ? '' : 's'}. Los valores se calculan hasta ${statisticsDate(response!.asOfDate)}.'),
          if (!customRange && staleDays != null && staleDays > 0)
            const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(spacing: 18, runSpacing: 8, children: [
                    Text(
                        'Último historial: ${statisticsDate(response?.quality.lastAvailableDate)}'),
                    Text(
                        'Actualización: ${statisticsDate(response?.asOfDate)}'),
                    Text('Hoy RD: ${formatCalendarDate(today)}'),
                    if (customRange)
                      Text(
                          'Referencia del período: ${statisticsDate(response?.asOfDate)}'),
                  ]))),
          const SizedBox(height: 12),
          DropdownButtonFormField<CurrentNumberOrder>(
            initialValue: controller.currentOrder,
            decoration: const InputDecoration(
                labelText: 'Ordenar por',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(
                  value: CurrentNumberOrder.mostDays,
                  child: Text('Más días sin aparecer')),
              DropdownMenuItem(
                  value: CurrentNumberOrder.leastDays,
                  child: Text('Menos días sin aparecer')),
              DropdownMenuItem(
                  value: CurrentNumberOrder.numberAscending,
                  child: Text('Número ascendente')),
              DropdownMenuItem(
                  value: CurrentNumberOrder.numberDescending,
                  child: Text('Número descendente')),
            ],
            onChanged: (value) {
              if (value != null) controller.setCurrentOrder(value);
            },
          ),
          const SizedBox(height: 12),
          for (final item in controller.orderedCurrentNumbers)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _NumberBall(item.number),
                title: Text(
                    item.daysSinceLastAppearance == null
                        ? 'Sin apariciones registradas'
                        : customRange
                            ? '${item.daysSinceLastAppearance} días hasta el final del período'
                            : '${item.daysSinceLastAppearance} días',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                    '${customRange ? 'Última aparición dentro del período' : 'Última aparición'}: ${statisticsDate(item.lastAppearanceDate)}'),
              ),
            ),
          const _Disclaimer(),
        ],
      ),
    );
  }
}

class _CombinedCurrentSituation extends StatelessWidget {
  final FirstPrizeStatisticsController controller;
  final DateTime? nowUtc;
  const _CombinedCurrentSituation(
      {required this.controller, required this.nowUtc});

  @override
  Widget build(BuildContext context) {
    final national = controller.numbersFor(StatisticsSeries.national);
    final ganaMas = controller.numbersFor(StatisticsSeries.ganaMas);
    return _StateBody(
      state: controller.numberState,
      error: controller.numberError,
      onRetry: controller.loadNumbers,
      emptyText: 'No hay información de situación actual.',
      child: ListView(
        key: const Key('combined-current-situation-list'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
              controller.appliedRange == null
                  ? 'Hoy RD: ${formatCalendarDate(dominicanCalendarDate((nowUtc ?? DateTime.now()).toUtc()))}'
                  : 'Referencia del período: ${formatCalendarDate(controller.appliedRange!.to)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (var index = 0; index < (national?.results.length ?? 0); index++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _NumberBall(national!.results[index].number),
                title: Text(
                    'Nacional: ${_currentDays(national.results[index], controller.appliedRange != null)}'),
                subtitle: Text(
                    'Gana Más: ${_currentDays(ganaMas!.results[index], controller.appliedRange != null)}'),
              ),
            ),
          const _Disclaimer(),
        ],
      ),
    );
  }

  static String _currentDays(NumberStatistics item, bool customRange) => item
              .daysSinceLastAppearance ==
          null
      ? 'sin apariciones'
      : customRange
          ? '${item.daysSinceLastAppearance} días hasta el final del período'
          : '${item.daysSinceLastAppearance} días sin aparecer';
}

class _CoverageCard extends StatelessWidget {
  final StatisticsQuality quality;
  final String title;
  const _CoverageCard(this.quality, {this.title = 'Cobertura histórica'});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _MetricRow(
                'Primera fecha', statisticsDate(quality.firstAvailableDate)),
            _MetricRow(
                'Última fecha', statisticsDate(quality.lastAvailableDate)),
            _MetricRow('Resultados analizados', '${quality.resultsAnalyzed}'),
            _MetricRow(
                'Intervalos verificados', '${quality.verifiedIntervals}'),
            _MetricRow('Intervalos incompletos',
                '${quality.incompleteCoverageIntervals}'),
            _MetricRow(
                'Fechas no verificadas',
                quality.unverifiedDates.isEmpty
                    ? 'Ninguna'
                    : quality.unverifiedDates
                        .map((item) => statisticsDate(item.date))
                        .join(', ')),
          ]),
        ),
      );
}

class _StateBody extends StatelessWidget {
  final StatisticsLoadState state;
  final String? error;
  final Future<void> Function() onRetry;
  final String emptyText;
  final Widget child;
  const _StateBody(
      {required this.state,
      required this.error,
      required this.onRetry,
      required this.emptyText,
      required this.child});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case StatisticsLoadState.loading:
        return Semantics(
          liveRegion: true,
          label: 'Cargando estadísticas de primera',
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      case StatisticsLoadState.empty:
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(emptyText, textAlign: TextAlign.center)));
      case StatisticsLoadState.error:
        return Semantics(
          liveRegion: true,
          label: 'Error al cargar estadísticas de primera',
          child: _FullError(onRetry: onRetry, message: error),
        );
      case StatisticsLoadState.data:
        return child;
    }
  }
}

class _FullError extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  const _FullError({required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 44, color: _blue),
          const SizedBox(height: 12),
          const Text('No pudimos cargar el análisis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message ?? 'Verifica la API de desarrollo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted)),
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar')),
        ]),
      ));
}

class _WarningCard extends StatelessWidget {
  final String text;
  const _WarningCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF7D6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD66B))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, color: _warning),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Color(0xFF6B4E00), fontWeight: FontWeight.w600)))
        ]),
      );
}

class _InfoMessage extends StatelessWidget {
  final String text;
  const _InfoMessage(this.text);
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: const Color(0xFFE7F0FF),
      child: Text(text,
          style: const TextStyle(color: _blue, fontWeight: FontWeight.w700)));
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(label, style: const TextStyle(color: _muted))),
          const SizedBox(width: 12),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: _ink, fontWeight: FontWeight.w800)))
        ]),
      );
}

class _NumberBall extends StatelessWidget {
  final String number;
  final bool large;
  const _NumberBall(this.number, {this.large = false});
  @override
  Widget build(BuildContext context) => Container(
        width: large ? 52 : 38,
        height: large ? 52 : 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _blue),
        child: Text(number,
            style: TextStyle(
                color: Colors.white,
                fontSize: large ? 19 : 14,
                fontWeight: FontWeight.w900)),
      );
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
            'Este análisis describe resultados históricos y no predice resultados futuros.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
