import 'package:flutter/material.dart';

import '../application/publishable_catalog.dart';
import '../domain/dreams_catalog.dart';
import 'dreams_content_state.dart';
import 'widgets/dreams_shared_widgets.dart';

class DreamTablePage extends StatefulWidget {
  final PublishableDreamsCatalog? catalog;

  const DreamTablePage({super.key, this.catalog});

  @override
  State<DreamTablePage> createState() => _DreamTablePageState();
}

class _DreamTablePageState extends State<DreamTablePage> {
  String _selectedNumber = '00';

  @override
  Widget build(BuildContext context) {
    final claims = widget.catalog?.claims
            .where((claim) => claim.number == _selectedNumber)
            .toList() ??
        const <DocumentaryClaim>[];
    return DreamsBranchScaffold(
      title: 'Tabla Dominicana de Sueños',
      description:
          'Consulta asociaciones documentadas y autorizadas para cada número.',
      showNotice: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona un número',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 58,
              mainAxisExtent: 48,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 100,
            itemBuilder: (context, index) {
              final number = index.toString().padLeft(2, '0');
              final selected = number == _selectedNumber;
              return Semantics(
                button: true,
                selected: selected,
                label: 'Número $number',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _selectedNumber = number),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF0648A8) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF0648A8)
                            : const Color(0xFFDCE4EF),
                      ),
                    ),
                    child: Text(
                      number,
                      style: TextStyle(
                        color:
                            selected ? Colors.white : const Color(0xFF17345C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Asociaciones para $_selectedNumber',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (claims.isEmpty)
            const DreamsContentStateView(
              state: DreamsContentState.noAuthorizedContent,
              detail:
                  'Todavía no hay asociaciones verificadas y autorizadas disponibles para este número.',
            )
          else
            ...claims.map((claim) => _ClaimCard(
                  claim: claim,
                  catalog: widget.catalog!,
                )),
        ],
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final DocumentaryClaim claim;
  final PublishableDreamsCatalog catalog;

  const _ClaimCard({required this.claim, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final entry = catalog.entryById(claim.catalogEntryId);
    final source = catalog.sourceById(claim.sourceId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.canonicalTerm,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Fuente: ${source.title}'),
            Text('Ubicación: ${claim.sourceLocation}'),
            if (entry.variants.isNotEmpty)
              Text(
                  'Variantes: ${entry.variants.map((item) => item.term).join(', ')}'),
          ],
        ),
      ),
    );
  }
}
