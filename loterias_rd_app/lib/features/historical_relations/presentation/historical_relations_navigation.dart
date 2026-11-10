import 'package:flutter/material.dart';

import '../../../app/app_features.dart';
import '../data/historical_relations_repository.dart';
import 'historical_relations_page.dart';

class HistoricalRelationsEntry extends StatelessWidget {
  final bool enabled;
  final HistoricalRelationsRepository? repository;

  const HistoricalRelationsEntry({
    super.key,
    this.enabled = AppFeatures.historicalRelationsEnabled,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Card(
        child: ListTile(
          key: const Key('historical-relations-entry'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE7F8ED),
            foregroundColor: Color(0xFF15803D),
            child: Icon(Icons.account_tree_outlined),
          ),
          title: const Text(
            'Relaciones Históricas',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: const Text('Qué números aparecieron después de otro'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openHistoricalRelations(
            context,
            enabled: enabled,
            repository: repository,
          ),
        ),
      ),
    );
  }
}

Future<void> openHistoricalRelations(
  BuildContext context, {
  bool enabled = AppFeatures.historicalRelationsEnabled,
  HistoricalRelationsRepository? repository,
}) async {
  if (!enabled) return;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => HistoricalRelationsPage(repository: repository),
  ));
}
