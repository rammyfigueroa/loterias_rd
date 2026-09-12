import 'package:flutter/material.dart';

// Use relative paths that correctly traverse from
// lib/features/results/presentation to lib/data and lib/domain.
import '../../../data/favorites_repository.dart';
import '../../../data/lottery_results_remote_source.dart';
import '../../../data/lottery_results_repository.dart';
import '../../../data/sample_data.dart';
import '../../../domain/lottery_result.dart';
import 'widgets/lottery_result_card.dart';
// import 'widgets/center_logo.dart';
import 'widgets/brand_logo.dart';
import 'widgets/lottery_icon.dart';
// import 'widgets/quick_features.dart';
import 'lotteries_page.dart';
import 'all_lotteries_page.dart';
import 'info_page.dart';
import 'result_detail_page.dart';
import 'stats_page.dart';

/// Home page showing a list of lottery results.
class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late final LotteryResultsRepository _repository;
  late final FavoritesRepository _favoritesRepository;
  late Future<List<LotteryResult>> _futureResults;
  String? _updatedAt;

  // Focus node for the search field so that we can programmatically
  // request focus (e.g. from the drawer quick search option).
  late final FocusNode _searchFocusNode;

  String _searchQuery = '';
  String? _selectedLottery;
  bool _showFavoritesOnly = false;
  int _currentIndex = 0;
  bool _historyView = false;
  DateTime? _historyFromDate;
  DateTime? _historyToDate;

  @override
  void initState() {
    super.initState();
    _repository = LotteryResultsRepository(
      remoteSource: LotteryResultsRemoteSource(),
      sampleSource: SampleLotteryResultsSource(),
    );
    _favoritesRepository = FavoritesRepository();
    _futureResults = _loadResults();

    // initialise the search focus node
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<List<LotteryResult>> _loadResults() async {
    final resp = await _repository.getLatestResults();
    final list = resp.results;
    // Capture the updated timestamp to display in the UI
    setState(() {
      _updatedAt = resp.updatedAt;
    });
    // Sort descending by date (string compare works for ISO or dd-MM formats)
    list.sort((a, b) => b.drawDate.compareTo(a.drawDate));
    return list;
  }

  List<String> _getAvailableLotteries(List<LotteryResult> results) {
    final set = <String>{};
    for (final r in results) {
      set.add(r.lotteryName);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  void _openLotteries(List<LotteryResult> results) async {
    final lotteries = _getAvailableLotteries(results);
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LotteriesPage(
          lotteries: lotteries,
          selected: _selectedLottery,
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedLottery = selected.isEmpty ? null : selected;
      });
    }
  }

  /// Horizontal quick lottery filters shown above the results list.
  ///
  /// This keeps the main screen faster to use than opening a full filter page
  /// every time. The full "Loterías" page remains available from the drawer.
  Widget _buildLotteryFilterChips(List<LotteryResult> allResults) {
    final lotteries = _getAvailableLotteries(allResults);

    Widget buildChip({required String label, required bool selected}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          selected: selected,
          selectedColor: Colors.white,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF003893),
          ),
          side: BorderSide(
            color: selected ? Colors.white : const Color(0xFFE5E7EB),
            width: 1,
          ),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onSelected: (_) {
            setState(() {
              _selectedLottery = label == 'Todas' ? null : label;
            });
          },
        ),
      );
    }

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          buildChip(label: 'Todas', selected: _selectedLottery == null),
          ...lotteries.map(
            (name) => buildChip(label: name, selected: _selectedLottery == name),
          ),
        ],
      ),
    );
  }



  DateTime? _parseDrawDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final isoMatch = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(text);
    if (isoMatch != null) {
      return DateTime.tryParse(
        '${isoMatch.group(1)!}-${isoMatch.group(2)!.padLeft(2, '0')}-${isoMatch.group(3)!.padLeft(2, '0')}',
      );
    }

    final latinMatch = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(text);
    if (latinMatch != null) {
      final day = latinMatch.group(1)!.padLeft(2, '0');
      final month = latinMatch.group(2)!.padLeft(2, '0');
      final year = latinMatch.group(3)!;
      return DateTime.tryParse('$year-$month-$day');
    }

    return DateTime.tryParse(text);
  }

  bool _isInsideHistoryRange(LotteryResult result) {
    final date = _parseDrawDate(result.drawDate);
    if (date == null) return true;

    final normalized = DateTime(date.year, date.month, date.day);
    if (_historyFromDate != null) {
      final from = DateTime(
        _historyFromDate!.year,
        _historyFromDate!.month,
        _historyFromDate!.day,
      );
      if (normalized.isBefore(from)) return false;
    }
    if (_historyToDate != null) {
      final to = DateTime(
        _historyToDate!.year,
        _historyToDate!.month,
        _historyToDate!.day,
      );
      if (normalized.isAfter(to)) return false;
    }
    return true;
  }

  String _formatDateFilter(DateTime? date, String fallback) {
    if (date == null) return fallback;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickHistoryDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initialDate = isFrom
        ? (_historyFromDate ?? _historyToDate ?? now)
        : (_historyToDate ?? _historyFromDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
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
      if (isFrom) {
        _historyFromDate = picked;
        if (_historyToDate != null && _historyToDate!.isBefore(picked)) {
          _historyToDate = picked;
        }
      } else {
        _historyToDate = picked;
        if (_historyFromDate != null && _historyFromDate!.isAfter(picked)) {
          _historyFromDate = picked;
        }
      }
    });
  }

  Widget _buildHistoryDateFilter() {
    Widget dateButton({
      required String label,
      required String value,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF003893),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF003893),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasFilter = _historyFromDate != null || _historyToDate != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          dateButton(
            label: 'Desde',
            value: _formatDateFilter(_historyFromDate, 'Elegir'),
            onTap: () => _pickHistoryDate(isFrom: true),
          ),
          const SizedBox(width: 8),
          dateButton(
            label: 'Hasta',
            value: _formatDateFilter(_historyToDate, 'Elegir'),
            onTap: () => _pickHistoryDate(isFrom: false),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _historyFromDate = null;
                  _historyToDate = null;
                });
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Provide a drawer with additional sections like the reference design.
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003893), Color(0xFF004fcf)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    BrandLogo(height: 54, forDarkBackground: true),
                    SizedBox(height: 4),
                    Text(
                      'Resultados al instante',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flash_on),
                title: const Text('Resultados al instante'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentIndex = 0;
                    _showFavoritesOnly = false;
                    _historyView = false;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Tus favoritas'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentIndex = 1;
                    _showFavoritesOnly = true;
                    _historyView = false;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Búsqueda rápida'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Focus the search field.
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                },
              ),
              // (Acerca de) entry will be added at the end of the menu below

              // New entry to view the list of all lotteries
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Loterías'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final selected = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const AllLotteriesPage(),
                    ),
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedLottery = selected.isEmpty ? null : selected;
                    });
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Estadísticas'),
                subtitle: const Text('Calientes, fríos y veces'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StatsPage(),
                    ),
                  );
                },
              ),

            // Move the 'Acerca de' entry to the end of the drawer menu
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InfoPage(),
                  ),
                );
              },
            ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        // Let the Scaffold insert the default hamburger icon when a Drawer is present.
        automaticallyImplyLeading: true,
        // Use a small minimalistic logo in the app bar title to save space.
        title: const BrandLogo(height: 42, forDarkBackground: true),
        centerTitle: true,
        // Keep the gradient to blend with the page background.
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
        toolbarHeight: 62,
      ),
      body: Container(
        // Apply a subtle background gradient to the entire body.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003893), Color(0xFF004fcf), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: FutureBuilder<List<LotteryResult>>(
          future: _futureResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState('Cargando resultados...');
            }
            if (snapshot.hasError) {
              return _buildErrorState(
                title: 'No pudimos cargar los resultados',
                message:
                    'Verifica tu conexión o intenta nuevamente en unos segundos.',
                onRetry: () {
                  setState(() {
                    _futureResults = _loadResults();
                  });
                },
              );
            }
            var results = snapshot.data ?? [];
            // Apply selected lottery filter
            if (_selectedLottery != null) {
              results = results
                  .where((r) => r.lotteryName == _selectedLottery)
                  .toList();
            }
            // Apply search filter
            if (_searchQuery.isNotEmpty) {
              results = results.where((r) {
                final query = _searchQuery.toLowerCase();
                return r.lotteryName.toLowerCase().contains(query) ||
                    r.drawName.toLowerCase().contains(query) ||
                    r.numbers.any((n) => n.toLowerCase().contains(query));
              }).toList();
            }
            if (_historyView) {
              results = results.where(_isInsideHistoryRange).toList();
            }
            // Sort ascending if in history view, descending otherwise.
            final sortedResults = List<LotteryResult>.from(results);
            if (_historyView) {
              sortedResults.sort((a, b) => a.drawDate.compareTo(b.drawDate));
            } else {
              sortedResults.sort((a, b) => b.drawDate.compareTo(a.drawDate));
            }
            return Column(
              children: [
                // Removed large center logo to provide more space for results.
                if (_updatedAt != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 12, right: 12, top: 0, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Actualizado: ${_updatedAt!}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: TextField(
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Buscar por nombre, sorteo o número',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                if (snapshot.data != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Filtrar lotería',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          'Resultados: ${sortedResults.length}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  _buildLotteryFilterChips(snapshot.data!),
                  const SizedBox(height: 4),
                ],
                if (_showFavoritesOnly) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tus favoritas',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Sorteos guardados para revisar más rápido',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_historyView) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historial',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Resultados anteriores agrupados por fecha',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildHistoryDateFilter(),
                ],
              // Removed quick feature highlights to maximise space for results
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _futureResults = _loadResults();
                      });
                      await _futureResults;
                    },
                    child: _historyView
                        ? _buildHistoryList(sortedResults)
                        : _buildResultsList(sortedResults),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            (states) => TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: states.contains(MaterialState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
            (states) => const IconThemeData(color: Colors.white),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (index == 3) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StatsPage(),
                ),
              );
              return;
            }
            setState(() {
              _currentIndex = index;
              if (index == 0) {
                // Inicio: show all results, latest first.
                _showFavoritesOnly = false;
                _historyView = false;
              } else if (index == 1) {
                // Favoritas: only results marked as favourite.
                _showFavoritesOnly = true;
                _historyView = false;
              } else if (index == 2) {
                // Historial: show all results sorted ascending by date.
                _showFavoritesOnly = false;
                _historyView = true;
              }
            });
          },
          backgroundColor: const Color(0xFF003893),
          indicatorColor: const Color(0xFF004fcf),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star),
              label: 'Favoritas',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Estadísticas',
            ),
          ],
        ),
      ),
    );
  }

  String _resultId(LotteryResult result) =>
      '${result.lotteryName}_${result.drawName}_${result.drawDate}';

  Widget _buildLoadingState(String message) {
    return Center(
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
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Un momento, estamos consultando la información más reciente.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
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
                  Icons.wifi_off_rounded,
                  color: Color(0xFF003893),
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
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
                  onPressed: onRetry,
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
    );
  }

  Widget _buildFavoritesEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.16),
                border: Border.all(color: Colors.white.withOpacity(0.24)),
              ),
              child: const Icon(Icons.star_border, size: 42, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes favoritas todavía',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toca la estrella en cualquier sorteo para guardarlo aquí.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.16),
                border: Border.all(color: Colors.white.withOpacity(0.24)),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba cambiar el filtro, limpiar la búsqueda o actualizar la pantalla.',
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

  /// Builds a simple list of results (home or favourites views).
  Widget _buildResultsList(List<LotteryResult> results) {
    if (_showFavoritesOnly) {
      return FutureBuilder<Set<String>>(
        future: _favoritesRepository.getFavoriteIds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState('Cargando favoritas...');
          }

          final favoriteIds = snapshot.data ?? <String>{};
          final favoriteResults = results
              .where((result) => favoriteIds.contains(_resultId(result)))
              .toList();

          if (favoriteResults.isEmpty) {
            return _buildFavoritesEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: favoriteResults.length,
            itemBuilder: (context, index) {
              return LotteryResultCard(
                result: favoriteResults[index],
                favoritesRepository: _favoritesRepository,
              );
            },
          );
        },
      );
    }

    if (results.isEmpty) {
      return _buildNoResultsState('No hay resultados disponibles.');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return LotteryResultCard(
          result: results[index],
          favoritesRepository: _favoritesRepository,
        );
      },
    );
  }

  /// Builds the history list grouped by draw date. Each date acts as a header for
  /// its group of results.
  Widget _buildHistoryList(List<LotteryResult> results) {
    if (results.isEmpty) {
      final hasFilter = _historyFromDate != null || _historyToDate != null;
      return _buildNoResultsState(
        hasFilter
            ? 'No hay resultados para el rango seleccionado.'
            : 'No hay resultados en el historial.',
      );
    }

    final Map<String, List<LotteryResult>> grouped = {};
    for (final result in results) {
      final date = result.drawDate;
      grouped.putIfAbsent(date, () => []).add(result);
    }
    final dates = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final groupResults = grouped[date] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Text(
                date,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 5),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                children: groupResults.asMap().entries.map((entry) {
                  final result = entry.value;
                  final isLast = entry.key == groupResults.length - 1;
                  return _HistoryResultTile(
                    result: result,
                    showDivider: !isLast,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResultDetailPage(result: result),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryResultTile extends StatelessWidget {
  final LotteryResult result;
  final bool showDivider;
  final VoidCallback onTap;

  const _HistoryResultTile({
    required this.result,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final numbers = result.numbers.take(3).toList();
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                )
              : null,
        ),
        child: Row(
          children: [
            LotteryIcon(
              lotteryName: result.lotteryName,
              size: 34,
              color: const Color(0xFF003893),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.lotteryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    result.drawName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniNumberBall(
                  number: numbers.isNotEmpty ? numbers[0] : '-',
                  color: const Color(0xFF003893),
                  textColor: Colors.white,
                  size: 36,
                ),
                const SizedBox(width: 6),
                _MiniNumberBall(
                  number: numbers.length > 1 ? numbers[1] : '-',
                  color: const Color(0xFFF3F4F6),
                  textColor: const Color(0xFF0F172A),
                  addBorder: true,
                  size: 36,
                ),
                const SizedBox(width: 6),
                _MiniNumberBall(
                  number: numbers.length > 2 ? numbers[2] : '-',
                  color: const Color(0xFFD90F2C),
                  textColor: Colors.white,
                  size: 36,
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNumberBall extends StatelessWidget {
  final String number;
  final Color color;
  final Color textColor;
  final bool addBorder;
  final double size;

  const _MiniNumberBall({
    required this.number,
    required this.color,
    required this.textColor,
    this.addBorder = false,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color:
              addBorder ? Colors.grey.shade300 : Colors.white.withOpacity(0.72),
          width: addBorder ? 1.8 : 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            offset: Offset(0, 2),
            color: Colors.black26,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}
