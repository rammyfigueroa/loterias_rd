import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_features.dart';
import '../../../data/favorites_repository.dart';
import '../../../data/favorites_session.dart';
import '../../../data/lottery_results_remote_source.dart';
import '../../../data/lottery_results_repository.dart';
import '../../../data/lottery_results_session.dart';
import '../../../data/sample_data.dart';
import '../../../domain/lottery_result.dart';
import '../../dreams_numbers/presentation/dreams_navigation.dart';
import '../../dreams_numbers/presentation/widgets/dreams_entry_widgets.dart';
import '../application/lottery_catalog.dart';
import 'info_page.dart';
import 'lottery_details_page.dart';
import 'result_detail_page.dart';
import 'stats_page.dart';
import 'widgets/lottery_home_widgets.dart';

class ResultsPage extends StatefulWidget {
  final bool dreamsNumbersEnabled;
  final LotteryResultsSession? resultsSession;
  final FavoritesSession? favoritesSession;

  const ResultsPage({
    super.key,
    this.dreamsNumbersEnabled = AppFeatures.dreamsNumbersEnabled,
    this.resultsSession,
    this.favoritesSession,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final LotteryResultsSession _resultsSession;
  late final bool _ownsResultsSession;
  late final FavoritesSession _favoritesSession;
  late final bool _ownsFavoritesSession;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
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
    _ownsResultsSession = widget.resultsSession == null;
    _resultsSession = widget.resultsSession ??
        LotteryResultsSession(
          loader: LotteryResultsRepository(
            remoteSource: LotteryResultsRemoteSource(),
            sampleSource: SampleLotteryResultsSource(),
          ),
        );
    _resultsSession.addListener(_onResultsChanged);
    _ownsFavoritesSession = widget.favoritesSession == null;
    _favoritesSession = widget.favoritesSession ??
        FavoritesSession(store: FavoritesRepository());
    _favoritesSession.addListener(_onFavoritesChanged);
    unawaited(_loadInitialResults());
    unawaited(_loadFavorites());
    _scheduleDayChangeRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayChangeTimer?.cancel();
    _resultsSession.removeListener(_onResultsChanged);
    if (_ownsResultsSession) _resultsSession.dispose();
    _favoritesSession.removeListener(_onFavoritesChanged);
    if (_ownsFavoritesSession) _favoritesSession.dispose();
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

  void _onResultsChanged() {
    if (mounted) setState(() {});
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    setState(() {
      _favoriteLotteryIds = _favoritesSession.favoriteLotteryIds;
    });
  }

  Future<void> _loadInitialResults() async {
    try {
      await _resultsSession.load();
    } catch (_) {}
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoritesSession.load();
      if (mounted) setState(() => _favoriteLotteryIds = favorites);
    } catch (_) {}
  }

  Future<void> _toggleFavorite(LotteryGroup group) async {
    final adding = !_favoritesSession.isFavorite(group.id);
    try {
      await _favoritesSession.toggleLottery(group.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            adding
                ? '${group.name} se agregó a Favoritas.'
                : '${group.name} se quitó de Favoritas.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el cambio en Favoritas.'),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    final nowUtc = DateTime.now().toUtc();
    setState(() => _nowUtc = nowUtc);
    _scheduleDayChangeRefresh(nowUtc: nowUtc);
    try {
      await Future.wait([_resultsSession.refresh(), _loadFavorites()]);
    } catch (_) {
      if (!mounted || !_resultsSession.hasData) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos actualizar. Conservamos los resultados anteriores.',
          ),
        ),
      );
    }
  }

  Future<void> _retryInitialLoad() async {
    try {
      await _resultsSession.refresh();
    } catch (_) {}
  }

  Future<void> _openLottery(LotteryGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LotteryDetailsPage(
          group: group,
          favoritesSession: _favoritesSession,
          nowUtc: _nowUtc,
        ),
      ),
    );
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
        drawer: _HomeDrawer(
          resultsSession: _resultsSession,
          dreamsNumbersEnabled: widget.dreamsNumbersEnabled,
          onSearch: () {
            Navigator.of(context).pop();
            _searchFocusNode.requestFocus();
          },
          onDreamsNumbers: () {
            Navigator.of(context).pop();
            openDreamsNumbersModule(
              context,
              enabled: widget.dreamsNumbersEnabled,
            );
          },
        ),
        body: SafeArea(bottom: false, child: _buildSessionBody()),
      ),
    );
  }

  Widget _buildSessionBody() {
    final response = _resultsSession.response;
    if (response == null) {
      if (_resultsSession.state == LotteryResultsSessionState.error) {
        return _ErrorHome(onRetry: _retryInitialLoad);
      }
      return const _LoadingHome();
    }
    return _buildLoadedHome(sortResultsNewestFirst(response.results));
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
            SliverToBoxAdapter(
              child: _ResultsUpdateStatus(
                isRefreshing: _resultsSession.isRefreshing,
                hasError: _resultsSession.error != null,
                updatedAt: _resultsSession.response?.updatedAt,
                onRetry: _refresh,
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
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final columns =
                        constraints.crossAxisExtent >= 340 && textScale <= 1.3
                            ? 3
                            : 2;
                    final spacing =
                        constraints.crossAxisExtent >= 380 ? 12.0 : 10.0;
                    final cardWidth = (constraints.crossAxisExtent -
                            spacing * (columns - 1)) /
                        columns;
                    final addedTextHeight = ((textScale - 1).clamp(0, 1)) * 34;
                    final cardHeight = (cardWidth * 1.52 + addedTextHeight)
                        .clamp(156.0, 230.0);
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
                            favoriteActionPending:
                                _favoritesSession.isPending(group.id),
                            onToggleFavorite: () => _toggleFavorite(group),
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
            if (widget.dreamsNumbersEnabled)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: DreamsModulePromoCard(
                    enabled: widget.dreamsNumbersEnabled,
                    onTap: () => openDreamsNumbersModule(
                      context,
                      enabled: widget.dreamsNumbersEnabled,
                    ),
                  ),
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

class _ResultsUpdateStatus extends StatelessWidget {
  final bool isRefreshing;
  final bool hasError;
  final String? updatedAt;
  final Future<void> Function() onRetry;

  const _ResultsUpdateStatus({
    required this.isRefreshing,
    required this.hasError,
    required this.updatedAt,
    required this.onRetry,
  });

  String? get _formattedUpdatedAt {
    final parsed = DateTime.tryParse(updatedAt ?? '');
    if (parsed == null) return null;
    final dominican = parsed.toUtc().add(dominicanUtcOffset);
    final day = dominican.day.toString().padLeft(2, '0');
    final month = dominican.month.toString().padLeft(2, '0');
    final hour = dominican.hour.toString().padLeft(2, '0');
    final minute = dominican.minute.toString().padLeft(2, '0');
    return '$day/$month/${dominican.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final lastUpdate = _formattedUpdatedAt;
    if (!isRefreshing && !hasError && lastUpdate == null) {
      return const SizedBox.shrink();
    }
    return Semantics(
      liveRegion: true,
      label: isRefreshing
          ? 'Actualizando resultados'
          : hasError
              ? 'Error de actualización. Se muestran datos anteriores.'
              : 'Última actualización $lastUpdate',
      child: ColoredBox(
        color: hasError ? const Color(0xFFFFF7E8) : const Color(0xFFEAF3FF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (isRefreshing)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  hasError ? Icons.cloud_off_outlined : Icons.schedule,
                  size: 18,
                  color: const Color(0xFF315A8C),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRefreshing
                      ? 'Actualizando resultados...'
                      : hasError
                          ? 'No se pudo actualizar. Mostrando datos anteriores.'
                          : 'Última actualización: $lastUpdate',
                  style: const TextStyle(
                    color: Color(0xFF315A8C),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasError)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final LotteryResultsSession resultsSession;
  final VoidCallback onSearch;
  final VoidCallback onDreamsNumbers;
  final bool dreamsNumbersEnabled;

  const _HomeDrawer({
    required this.resultsSession,
    required this.onSearch,
    required this.onDreamsNumbers,
    required this.dreamsNumbersEnabled,
  });

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
          if (dreamsNumbersEnabled)
            DreamsDrawerTile(
              enabled: dreamsNumbersEnabled,
              onTap: onDreamsNumbers,
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.insights_outlined),
            title: const Text('Estadísticas'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StatsPage(resultsSession: resultsSession),
                ),
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
