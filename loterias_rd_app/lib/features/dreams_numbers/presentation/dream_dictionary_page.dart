import 'package:flutter/material.dart';

import '../application/dreams_catalog_search.dart';
import '../application/publishable_catalog.dart';
import 'dreams_content_state.dart';
import 'widgets/dreams_shared_widgets.dart';

const dreamDictionaryCategories = <String>[
  'Animales',
  'Agua y naturaleza',
  'Personas y familia',
  'Difuntos',
  'Religión',
  'Dinero',
  'Amor',
  'Cuerpo',
  'Lugares',
  'Objetos',
  'Situaciones',
  'Creencias populares',
];

class DreamDictionaryPage extends StatefulWidget {
  final PublishableDreamsCatalog? catalog;

  const DreamDictionaryPage({super.key, this.catalog});

  @override
  State<DreamDictionaryPage> createState() => _DreamDictionaryPageState();
}

class _DreamDictionaryPageState extends State<DreamDictionaryPage> {
  final _controller = TextEditingController();
  List<CatalogSearchResult> _results = const [];
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    setState(() {
      _searched = value.trim().isNotEmpty;
      _results = widget.catalog == null || !_searched
          ? const []
          : widget.catalog!.search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DreamsBranchScaffold(
      title: 'Diccionario de Sueños',
      description:
          'Explora conceptos, variantes lingüísticas y fuentes documentales.',
      showNotice: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            onChanged: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar concepto',
              hintText: 'Escribe un símbolo o expresión',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Categorías previstas',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dreamDictionaryCategories
                .map((category) => Chip(
                      avatar: const Icon(Icons.lock_clock_outlined, size: 18),
                      label: Text(category),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          if (widget.catalog == null)
            const DreamsContentStateView(
              state: DreamsContentState.preparing,
            )
          else if (_searched && _results.isEmpty)
            const DreamsContentStateView(state: DreamsContentState.noResults)
          else if (!_searched)
            const DreamsContentStateView(
              state: DreamsContentState.noResults,
              detail:
                  'Escribe un término para consultar el catálogo autorizado.',
            )
          else
            ..._results.map((result) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(result.entry.canonicalTerm),
                    subtitle: Text(
                      result.ambiguous
                          ? 'Coincidencia ambigua · ${result.matchedTerm}'
                          : 'Coincidencia: ${result.matchedTerm}',
                    ),
                    trailing: Text(
                      result.claims.map((claim) => claim.number).join(', '),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
