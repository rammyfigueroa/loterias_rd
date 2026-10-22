import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _ResultsPageState extends State<ResultsPage> with WidgetsBindingObserver {
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
  DateTime _nowUtc = DateTime.now().toUtc();
  Timer? _dayChangeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = LotteryResultsRepository(
      remoteSource: LotteryResultsRemoteSource(),
      sampleSource: SampleLotteryResultsSource(),
    );
    _futureResults = _loadResults();
    _loadFavorites();
    _scheduleDayChangeRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayChangeTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDominicanDate();
    }
  }

  void _refreshDominicanDate() {
    final nowUtc = DateTime.now().toUtc();
    if (mounted) setState(() => _nowUtc = nowUtc);
    _scheduleDayChangeRefresh(nowUtc: nowUtc);
  }

  void _scheduleDayChangeRefresh({DateTime? nowUtc}) {
    _dayChangeTimer?.cancel();
    final currentUtc = nowUtc ?? DateTime.now().toUtc();
    final delay =
        untilNextDominicanDay(currentUtc) + const Duration(seconds: 1);
    _dayChangeTimer = Timer(delay, _refreshDominicanDate);
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
    final nowUtc = DateTime.now().toUtc();
    setState(() {
      _futureResults = next;
      _nowUtc = nowUtc;
    });
    _scheduleDayChangeRefresh(nowUtc: nowUtc);
    await Future.wait([next, _loadFavorites()]);
  }

  Future<void> _openLottery(LotteryGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LotteryDetailsPage(
          group: group,
          favoritesRepository: _favoritesRepository,
          initiallyFavorite: _favoriteLotteryIds.contains(group.id),
          nowUtc: _nowUtc,
        ),
      ),
    );
    await _loadFavorites();
  }

  void _openResult(LotteryResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultDetailPage(result: result, nowUtc: _nowUtc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
              sliver: SliverToBoxAdapter(
                child: LotteryFilterChips(
                  selected: _selectedFilter,
                  onSelected: (value) =>
                      setState(() => _selectedFilter = value),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 14),
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
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 340 ? 3 : 2;
                    final spacing =
                        constraints.crossAxisExtent >= 380 ? 12.0 : 10.0;
                    final cardWidth = (constraints.crossAxisExtent -
                            spacing * (columns - 1)) /
                        columns;
                    final cardHeight = (cardWidth * 1.52).clamp(156.0, 174.0);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: cardHeight,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final group = groups[index];
                          return LotteryCard(
                            group: group,
                            isFavorite: _favoriteLotteryIds.contains(group.id),
                            hasResultsToday: lotteryHasResultsToday(
                              group,
                              nowUtc: _nowUtc,
                            ),
                            onTap: () => _openLottery(group),
                          );
                        },
                        childCount: groups.length,
                      ),
                    );
                  },
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
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
                    nowUtc: _nowUtc,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF063E96), Color(0xFF0875DA)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final logoWidth =
                    (constraints.maxWidth * .72).clamp(210.0, 270.0);
                return SizedBox(
                  height: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Abrir menú',
                          onPressed: onMenu,
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                          ),
                          iconSize: 28,
                        ),
                      ),
                      IgnorePointer(
                        child: Image.asset(
                          'assets/branding/logo_horizontal.png',
                          width: logoWidth,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 340),
                child: Text(
                  'Resultados de las principales\nloterías de la República Dominicana',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE5F0FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26001642),
                    blurRadius: 16,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: LotterySearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
              ),
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
                  color: const Color(0xFF081426),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            label: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final VoidCallback onSearch;

  const _HomeDrawer({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: topInset + 174,
            padding: EdgeInsets.fromLTRB(22, topInset + 20, 22, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF063E96), Color(0xFF0875DA)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/branding/logo_horizontal.png',
                  width: double.infinity,
                  height: 78,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Resultados de las principales\nloterías de la República Dominicana',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE5F0FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.search),
            title: const Text('Buscar resultados'),
            onTap: onSearch,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
