import 'package:flutter/material.dart';

import '../../first_prize_statistics/domain/first_prize_statistics.dart';
import '../application/historical_relations_controller.dart';
import '../data/historical_relations_repository.dart';
import '../domain/historical_relations.dart';

class HistoricalRelationsPage extends StatefulWidget {
  final HistoricalRelationsRepository? repository;

  const HistoricalRelationsPage({super.key, this.repository});

  @override
  State<HistoricalRelationsPage> createState() =>
      _HistoricalRelationsPageState();
}

class _HistoricalRelationsPageState extends State<HistoricalRelationsPage> {
  late final HistoricalRelationsController controller;

  @override
  void initState() {
    super.initState();
    controller = HistoricalRelationsController(
      widget.repository ?? LocalHistoricalRelationsRepository(),
    )..addListener(_refresh);
    controller.load();
  }

  @override
  void dispose() {
    controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _date(DateTime? value) => value == null
      ? '--/--/----'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _isoDate(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    return _date(parsed);
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = from
        ? controller.pendingFrom ?? DateTime(2026, 4, 1)
        : controller.pendingTo ?? DateTime(2026, 4, 11);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    from ? controller.setPendingFrom(picked) : controller.setPendingTo(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relaciones Históricas')),
      backgroundColor: const Color(0xFFF4F7FB),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _filters(),
          const SizedBox(height: 12),
          _content(),
        ],
      ),
    );
  }

  Widget _filters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<StatisticsDrawOption>(
              key: const Key('historical-series-selector'),
              isExpanded: true,
              initialValue: controller.selectedSeries,
              decoration: const InputDecoration(labelText: 'Lotería y sorteo'),
              items: controller.seriesOptions
                  .where((item) => item.available)
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.selectSeries(value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('historical-number-selector'),
              isExpanded: true,
              initialValue: controller.originNumber,
              decoration: const InputDecoration(labelText: 'Número origen'),
              items: List.generate(
                      100, (index) => index.toString().padLeft(2, '0'))
                  .map((number) => DropdownMenuItem(
                        value: number,
                        child: Text(number),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.selectNumber(value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HistoricalCoverage>(
              key: const Key('historical-coverage-selector'),
              isExpanded: true,
              initialValue: controller.coverage,
              decoration: const InputDecoration(labelText: 'Cobertura'),
              items: HistoricalCoverage.values
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.selectCoverage(value);
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final fromButton = OutlinedButton.icon(
                key: const Key('historical-from'),
                onPressed: () => _pickDate(from: true),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Desde: ${_date(controller.pendingFrom)}'),
              );
              final toButton = OutlinedButton.icon(
                key: const Key('historical-to'),
                onPressed: () => _pickDate(from: false),
                icon: const Icon(Icons.event_outlined),
                label: Text('Hasta: ${_date(controller.pendingTo)}'),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [fromButton, const SizedBox(height: 8), toButton],
                );
              }
              return Row(
                children: [
                  Expanded(child: fromButton),
                  const SizedBox(width: 8),
                  Expanded(child: toButton),
                ],
              );
            }),
            if (controller.rangeError != null) ...[
              const SizedBox(height: 8),
              Text(controller.rangeError!,
                  style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('historical-all-history'),
                  onPressed: controller.useAllHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Todo el historial'),
                ),
                FilledButton.icon(
                  key: const Key('historical-apply-range'),
                  onPressed: controller.applyRange,
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar fechas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    switch (controller.state) {
      case HistoricalRelationsLoadState.idle:
      case HistoricalRelationsLoadState.loading:
        return const Center(
          key: Key('historical-loading'),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      case HistoricalRelationsLoadState.error:
        return _messageCard(
          key: const Key('historical-error'),
          icon: Icons.error_outline,
          title: 'No fue posible cargar los datos',
          message: controller.errorMessage ?? 'Intenta nuevamente.',
          action: TextButton(
            onPressed: controller.load,
            child: const Text('Reintentar'),
          ),
        );
      case HistoricalRelationsLoadState.empty:
        return _messageCard(
          key: const Key('historical-empty'),
          icon: Icons.manage_search,
          title: 'Sin transiciones verificables',
          message:
              'No hay una transición verificable dentro de este período para el número ${controller.originNumber}.',
        );
      case HistoricalRelationsLoadState.data:
        return _results(controller.result!);
    }
  }

  Widget _results(HistoricalRelationsResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _metric('Número origen', result.originNumber),
                _metric('Apariciones', '${result.originAppearances}'),
                _metric('Transiciones', '${result.totalTransitions}'),
                _metric('Cobertura', result.coverage.label),
                _metric('Primera fecha',
                    _isoDate(result.quality.firstAvailableDate)),
                _metric(
                    'Última fecha', _isoDate(result.quality.lastAvailableDate)),
              ],
            ),
          ),
        ),
        if (result.quality.incompleteCoverageTransitions > 0 ||
            result.warnings.isNotEmpty)
          Card(
            color: const Color(0xFFFFF7E6),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                result.warnings.join(' '),
                key: const Key('historical-coverage-warning'),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text('Números siguientes',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...result.destinations.map((item) => Card(
              key: Key('historical-destination-${item.nextNumber}'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(child: Text(item.nextNumber)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.transitionCount} transiciones · ${(item.relativeFrequency * 100).toStringAsFixed(1)} %',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Última transición: ${_isoDate(item.lastTransitionDate)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFFEAF2FF),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(result.disclaimer,
                key: const Key('historical-disclaimer')),
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value) => SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF667085))),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      );

  Widget _messageCard({
    required Key key,
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF003893)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}
