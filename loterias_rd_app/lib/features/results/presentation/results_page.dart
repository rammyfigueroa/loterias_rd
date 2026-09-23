import 'package:flutter/material.dart';

import '../../../data/favorites_repository.dart';
import '../../../data/lottery_results_remote_source.dart';
import '../../../data/lottery_results_repository.dart';
import '../../../data/sample_data.dart';
import '../../../domain/lottery_result.dart';
import '../application/lottery_catalog.dart';
import 'info_page.dart';
import 'lottery_details_page.dart';
import 'result_detail_page.dart';
import 'stats_page.dart';
import 'widgets/lottery_home_widgets.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final LotteryResultsRepository _repository;
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late Future<List<LotteryResult>> _futureResults;
  Set<String> _favoriteLotteryIds = <String>{};
  String _query = '';
  String _selectedFilter = 'Todas';
  bool _showAllRecent = false;

  @override
  void initState() {
    super.initState();
    _repository = LotteryResultsRepository(
      remoteSource: LotteryResultsRemoteSource(),
      sampleSource: SampleLotteryResultsSource(),
    );
    _futureResults = _loadResults();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<List<LotteryResult>> _loadResults() async {
    final response = await _repository.getLatestResults();
    return sortResultsNewestFirst(response.results);
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesRepository.getFavoriteLotteryIds();
    if (mounted) setState(() => _favoriteLotteryIds = favorites);
  }

  Future<void> _refresh() async {
    final next = _loadResults();
    setState(() => _futureResults = next);
    await Future.wait([next, _loadFavorites()]);
  }

  Future<void> _openLottery(LotteryGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LotteryDetailsPage(
          group: group,
          favoritesRepository: _favoritesRepository,
          initiallyFavorite: _favoriteLotteryIds.contains(group.id),
        ),
      ),
    );
    await _loadFavorites();
  }

  void _openResult(LotteryResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultDetailPage(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0648A8),
      drawer: _HomeDrawer(onSearch: () {
        Navigator.of(context).pop();
        _searchFocusNode.requestFocus();
      }),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<LotteryResult>>(
          future: _futureResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingHome();
            }
            if (snapshot.hasError) return _ErrorHome(onRetry: _refresh);
            return _buildLoadedHome(snapshot.data ?? const <LotteryResult>[]);
          },
        ),
      ),
    );
  }

  Widget _buildLoadedHome(List<LotteryResult> allResults) {
    final searchedResults = searchResults(allResults, _query);
    var groups = groupResultsByLottery(searchedResults);
    if (_selectedFilter == 'Favoritas') {
      groups = groups
          .where((group) => _favoriteLotteryIds.contains(group.id))
          .toList();
    } else if (_selectedFilter == 'Recientes') {
      groups = groups.take(6).toList();
    }

    final recentResults = sortResultsNewestFirst(searchedResults);
    final visibleRecent = _showAllRecent
        ? recentResults
        : recentResults.take(6).toList(growable: false);

    return ColoredBox(
      color: const Color(0xFFF4F7FB),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onSearchChanged: (value) => setState(() => _query = value),
                onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: LotteryFilterChips(
                  selected: _selectedFilter,
                  onSelected: (value) =>
                      setState(() => _selectedFilter = value),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 22, 16, 12),
              sliver:
                  SliverToBoxAdapter(child: _SectionTitle(title: 'Loterías')),
            ),
            if (groups.isEmpty)
              SliverToBoxAdapter(
                child: ResultsEmptyState(
                  title: _selectedFilter == 'Favoritas'
                      ? 'No tienes loterías favoritas'
                      : 'No encontramos resultados',
                  message: _selectedFilter == 'Favoritas'
                      ? 'Abre una lotería y toca la estrella para guardarla aquí.'
                      : 'Prueba con otro nombre, fecha o número.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 165,
                    mainAxisExtent: 176,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final group = groups[index];
                      return LotteryCard(
                        group: group,
                        isFavorite: _favoriteLotteryIds.contains(group.id),
                        onTap: () => _openLottery(group),
                      );
                    },
                    childCount: groups.length,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'Resultados recientes',
                  actionLabel: recentResults.length > 6
                      ? (_showAllRecent ? 'Ver menos' : 'Ver todos')
                      : null,
                  onAction: () =>
                      setState(() => _showAllRecent = !_showAllRecent),
                ),
              ),
            ),
            if (visibleRecent.isEmpty)
              const SliverToBoxAdapter(
                child: ResultsEmptyState(
                  title: 'Sin resultados recientes',
                  message: 'Actualiza la pantalla para intentarlo nuevamente.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverList.separated(
                  itemCount: visibleRecent.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => RecentResultCard(
                    result: visibleRecent[index],
                    onTap: () => _openResult(visibleRecent[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onMenu;

  const _HomeHeader({
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0648A8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Abrir menú',
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu, color: Colors.white),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Sorteos Dominicanos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 52, right: 12),
              child: Text(
                'Resultados de las principales loterías de la República Dominicana',
                style: TextStyle(color: Color(0xFFDCEAFE), height: 1.35),
              ),
            ),
            const SizedBox(height: 20),
            LotterySearchBar(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: onSearchChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({this.title = '', this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final VoidCallback onSearch;

  const _HomeDrawer({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0648A8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.casino_outlined, color: Colors.white, size: 38),
                  SizedBox(height: 12),
                  Text(
                    'Sorteos Dominicanos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Buscar resultados'),
              onTap: onSearch,
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Estadísticas'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InfoPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF4F7FB),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando resultados...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorHome extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorHome({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4F7FB),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 54),
              const SizedBox(height: 14),
              Text(
                'No pudimos cargar los resultados',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Comprueba tu conexión e inténtalo nuevamente.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
