import 'package:flutter/material.dart';

import '../../../app/app_features.dart';
import 'dreams_numbers_home_page.dart';

Future<void> openDreamsNumbersModule(
  BuildContext context, {
  bool enabled = AppFeatures.dreamsNumbersEnabled,
}) {
  if (!enabled) return Future<void>.value();

  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const DreamsNumbersHomePage()),
  );
}
