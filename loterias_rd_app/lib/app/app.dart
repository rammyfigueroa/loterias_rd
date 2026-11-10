import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/lottery_results_remote_source.dart';
import '../data/lottery_results_repository.dart';
import '../data/lottery_results_session.dart';
import '../data/favorites_repository.dart';
import '../data/favorites_session.dart';
import '../data/sample_data.dart';
import '../features/results/presentation/results_page.dart';
import 'theme/app_theme.dart';

/// Root widget for the Sorteos Dominicanos application.
class LoteriasRdApp extends StatefulWidget {
  const LoteriasRdApp({super.key});

  @override
  State<LoteriasRdApp> createState() => _LoteriasRdAppState();
}

class _LoteriasRdAppState extends State<LoteriasRdApp> {
  late final LotteryResultsSession _resultsSession;
  late final FavoritesSession _favoritesSession;

  @override
  void initState() {
    super.initState();
    _resultsSession = LotteryResultsSession(
      loader: LotteryResultsRepository(
        remoteSource: LotteryResultsRemoteSource(),
        sampleSource: SampleLotteryResultsSource(),
      ),
    );
    _favoritesSession = FavoritesSession(store: FavoritesRepository());
  }

  @override
  void dispose() {
    _resultsSession.dispose();
    _favoritesSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sorteos Dominicanos',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ResultsPage(
        resultsSession: _resultsSession,
        favoritesSession: _favoritesSession,
      ),
    );
  }
}
