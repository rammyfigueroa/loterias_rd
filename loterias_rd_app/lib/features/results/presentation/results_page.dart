import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../data/favorites_repository.dart';
import '../data/lottery_results_repository.dart';
import '../domain/lottery_result.dart';
import 'result_detail_page.dart';
import 'widgets/lottery_filter_bar.dart';
import 'widgets/lottery_result_card.dart';
import 'widgets/results_header.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({required this.repository, super.key});

  final LotteryResultsRepository repository;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<LotteryResultsResponse> _future;
  final _favoritesRepository = FavoritesRepository();
  Set<String> _favoriteKeys = <String>{};
  var _query = '';
  var _selectedLottery = 'Todas';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getLatestResults();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesRepository.loadFavorites();
    if (!mounted) return;
    setState(() => _favoriteKeys = favorites);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.getLatestResults();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Actualizar resultados',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<LotteryResultsResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          final response = snapshot.data;
          final results = response?.results ?? const <LotteryResult>[];
          final visibleResults = _filterResults(results);
          final lotteries = _lotteryNames(results);

          return RefreshIndicator(
            color: AppTheme.blue,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: ResultsHeader(
                    totalResults: results.length,
                    loadedFromFallback: response?.loadedFromFallback ?? false,
                    message: response?.message,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeaderDelegate(
                    child: LotteryFilterBar(
                      lotteries: lotteries,
                      selectedLottery: _selectedLottery,
                      query: _query,
                      onLotteryChanged: (value) {
                        setState(() => _selectedLottery = value);
                      },
                      onQueryChanged: (value) {
                        setState(() => _query = value);
                      },
                    ),
                  ),
                ),
                if (visibleResults.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index.isOdd) return const SizedBox(height: 12);
                          final resultIndex = index ~/ 2;
                          final result = visibleResults[resultIndex];
                          return LotteryResultCard(
                            result: result,
                            isFavorite: _favoriteKeys.contains(result.favoriteKey),
                            onFavoriteToggle: () => _toggleFavorite(result),
                            onTap: () => _openDetail(result),
                          );
                        },
                        childCount: visibleResults.length * 2 - 1,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<LotteryResult> _filterResults(List<LotteryResult> results) {
    final normalizedQuery = _query.trim().toLowerCase();
    return results.where((result) {
      final matchesLottery = _selectedLottery == 'Todas' ||
          (_selectedLottery == 'Favoritos' &&
              _favoriteKeys.contains(result.favoriteKey)) ||
          result.lotteryName == _selectedLottery;
      final matchesQuery = normalizedQuery.isEmpty ||
          result.lotteryName.toLowerCase().contains(normalizedQuery) ||
          result.drawName.toLowerCase().contains(normalizedQuery) ||
          result.numbers.join(' ').contains(normalizedQuery);
      return matchesLottery && matchesQuery;
    }).toList(growable: false);
  }

  List<String> _lotteryNames(List<LotteryResult> results) {
    final names = results.map((result) => result.lotteryName).toSet().toList()
      ..sort();
    return ['Todas', 'Favoritos', ...names];
  }

  Future<void> _toggleFavorite(LotteryResult result) async {
    final favorites = await _favoritesRepository.toggleFavorite(result.favoriteKey);
    if (!mounted) return;
    setState(() => _favoriteKeys = favorites);

    final isFavorite = favorites.contains(result.favoriteKey);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Agregado a favoritos' : 'Quitado de favoritos',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openDetail(LotteryResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDetailState) {
              final isFavorite = _favoriteKeys.contains(result.favoriteKey);
              return ResultDetailPage(
                result: result,
                isFavorite: isFavorite,
                onFavoriteToggle: () async {
                  final favorites = await _favoritesRepository.toggleFavorite(
                    result.favoriteKey,
                  );
                  if (!mounted) return;
                  setState(() => _favoriteKeys = favorites);
                  setDetailState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FilterHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 132;

  @override
  double get maxExtent => 132;

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando resultados...'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No encontramos resultados con ese filtro.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prueba con otra loteria, sorteo o numero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
