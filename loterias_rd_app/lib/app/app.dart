import 'package:flutter/material.dart';

import '../features/results/presentation/results_page.dart';
import 'theme/app_theme.dart';

/// Root widget for the Sorteos Dominicanos application.
class LoteriasRdApp extends StatelessWidget {
  const LoteriasRdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sorteos Dominicanos',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const ResultsPage(),
    );
  }
}