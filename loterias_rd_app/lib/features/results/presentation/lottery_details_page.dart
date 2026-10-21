import 'package:flutter/material.dart';

import '../../../data/favorites_repository.dart';
import '../../../domain/lottery_result.dart';
import '../application/lottery_catalog.dart';
import '../application/result_share_service.dart';
import 'result_detail_page.dart';
import 'widgets/lottery_home_widgets.dart';
import 'widgets/lottery_icon.dart';

class LotteryDetailsPage extends StatefulWidget {
  final LotteryGroup group;
  final FavoritesRepository favoritesRepository;
  final bool initiallyFavorite;

  const LotteryDetailsPage({
    super.key,
    required this.group,
    required this.favoritesRepository,
    required this.initiallyFavorite,
  });

  @override
  State<LotteryDetailsPage> createState() => _LotteryDetailsPageState();
}

class _LotteryDetailsPageState extends State<LotteryDetailsPage> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initiallyFavorite;
  }

  Future<void> _toggleFavorite() async {
    final next =
        await widget.favoritesRepository.toggleFavoriteLottery(widget.group.id);
    if (mounted) setState(() => _isFavorite = next);
  }

  void _openResult(LotteryResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultDetailPage(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.group.results;
    final latestDate = results.isEmpty ? '' : results.first.drawDate;
    final recent = results.where((r) => r.drawDate == latestDate).toList();
    final history = results.where((r) => r.drawDate != latestDate).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: LotteryIcon(
                  lotteryName: widget.group.name,
                  size: 30,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip:
                  _isFavorite ? 'Quitar de favoritas' : 'Agregar a favoritas',
              onPressed: _toggleFavorite,
              icon: Icon(_isFavorite ? Icons.star : Icons.star_outline),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xB3FFFFFF),
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Recientes'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _LotteryResultsList(
                results: recent,
                emptyMessage: 'No hay resultados recientes disponibles.',
                onOpen: _openResult,
              ),
              _LotteryResultsList(
                results: history,
                emptyMessage: 'Todavía no hay resultados anteriores.',
                onOpen: _openResult,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LotteryResultsList extends StatelessWidget {
  final List<LotteryResult> results;
  final String emptyMessage;
  final ValueChanged<LotteryResult> onOpen;

  const _LotteryResultsList({
    required this.results,
    required this.emptyMessage,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return ResultsEmptyState(title: 'Sin resultados', message: emptyMessage);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final result = results[index];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE3EAF3),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141B3555),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.drawName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              result.drawDate,
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Abrir detalle',
                        onPressed: () => onOpen(result),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final numberCount = resultNumbers(result).length;
                      final isShort = hasShortVisibleNumberGroup(result);
                      if (isShort) {
                        const spacing = 12.0;
                        final ballSize = responsiveShortGroupBallSize(
                          result: result,
                          availableWidth: constraints.maxWidth,
                          spacing: spacing,
                          standardSize: 64,
                          maximumShortSize: 92,
                        );
                        return SizedBox(
                          width: double.infinity,
                          child: ResultNumberBalls(
                            result: result,
                            size: ballSize,
                            spacing: spacing,
                            alignment: WrapAlignment.center,
                          ),
                        );
                      }
                      final ballsInFirstRow = numberCount.clamp(1, 4);
                      const spacing = 10.0;
                      final availableBallWidth = (constraints.maxWidth -
                              spacing * (ballsInFirstRow - 1)) /
                          ballsInFirstRow;
                      final ballSize = availableBallWidth.clamp(58.0, 64.0);
                      return SizedBox(
                        width: double.infinity,
                        child: ResultNumberBalls(
                          result: result,
                          size: ballSize,
                          spacing: spacing,
                          alignment: WrapAlignment.center,
                        ),
                      );
                    },
                  ),
                  if (result.prizes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: result.prizes
                          .map(
                            (prize) => Text(
                              '${prize.label}: ${prize.number}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onOpen(result),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Detalle'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => shareLotteryResult(context, result),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Compartir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
