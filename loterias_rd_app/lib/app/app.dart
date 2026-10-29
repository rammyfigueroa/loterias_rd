import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const ResultsPage(),
    );
  }
}
