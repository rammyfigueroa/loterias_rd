import 'package:flutter/material.dart';

import '../features/results/data/lottery_results_repository.dart';
import '../features/results/presentation/results_page.dart';
import 'theme/app_theme.dart';

class LoteriasRdApp extends StatelessWidget {
  const LoteriasRdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loterias RD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: ResultsPage(repository: LotteryResultsRepository()),
    );
  }
}
