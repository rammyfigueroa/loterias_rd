import 'package:flutter/material.dart';

import '../../../data/lottery_results_remote_source.dart';
import '../../../data/lottery_results_repository.dart';
import '../../../data/sample_data.dart';
import '../../../domain/lottery_result.dart';
import 'widgets/lottery_icon.dart';

/// A page that lists all available lotteries with search functionality.
///
/// This page allows the user to browse the list of lotteries available in
/// the latest results. A search field filters the list by name. Each entry
/// shows a simple icon for the lottery and its name. Tapping a lottery
/// returns its name to the caller so that it can be used as a filter.
class AllLotteriesPage extends StatefulWidget {
  const AllLotteriesPage({super.key});

  @override
  State<AllLotteriesPage> createState() => _AllLotteriesPageState();
}

class _AllLotteriesPageState extends State<AllLotteriesPage> {
  late final LotteryResultsRepository _repository;
  late Future<List<LotteryResult>> _futureResults;
  List<String> _lotteries = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = LotteryResultsRepository(
      remoteSource: LotteryResultsRemoteSource(),
      sampleSource: SampleLotteryResultsSource(),
    );
    _futureResults = _loadLotteries();
  }

  Future<List<LotteryResult>> _loadLotteries() async {
    final resp = await _repository.getLatestResults();
    final set = <String>{};
    for (final r in resp.results) {
      set.add(r.lotteryName);
    }
    final list = set.toList();
    list.sort();
    setState(() {
      _lotteries = list;
    });
    return resp.results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loterías'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003893), Color(0xFF004fcf), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Buscar lotería',
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
            Expanded(
              child: FutureBuilder<List<LotteryResult>>(
                future: _futureResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off, color: Colors.white, size: 44),
                            const SizedBox(height: 12),
                            Text(
                              'No pudimos cargar las loterías.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Verifica tu conexión o intenta nuevamente.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _futureResults = _loadLotteries();
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Filter lotteries by search query.
                  final filtered = _lotteries.where((name) {
                    if (_searchQuery.isEmpty) return true;
                    return name.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No hay loterías que coincidan.'));
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final name = filtered[index];
                      return ListTile(
                        leading: LotteryIcon(
                          lotteryName: name,
                          size: 32,
                          color: const Color(0xFF003893),
                        ),
                        title: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                        ),
                        tileColor: Colors.transparent,
                        onTap: () {
                          // Return the selected lottery name back to the caller.
                          Navigator.of(context).pop(name);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}