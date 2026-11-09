import 'package:flutter/material.dart';

import '../application/dream_description_analyzer.dart';
import '../application/publishable_catalog.dart';
import 'dreams_content_state.dart';
import 'widgets/dreams_shared_widgets.dart';

class DreamDecoderPage extends StatefulWidget {
  final PublishableDreamsCatalog? catalog;

  const DreamDecoderPage({super.key, this.catalog});

  @override
  State<DreamDecoderPage> createState() => _DreamDecoderPageState();
}

class _DreamDecoderPageState extends State<DreamDecoderPage> {
  final _controller = TextEditingController();
  DreamAnalysisResult? _result;
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _result = widget.catalog == null || _controller.text.trim().isEmpty
          ? null
          : widget.catalog!.analyze(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return DreamsBranchScaffold(
      title: 'Descifrador de Sueños',
      description:
          'El análisis ocurre únicamente en tu dispositivo y usa coincidencias documentadas.',
      showNotice: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Describe tu sueño',
              alignLabelWithHint: true,
              hintText: 'Escribe aquí los elementos que recuerdas.',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Descifrar sueño'),
          ),
          const SizedBox(height: 20),
          if (!_submitted)
            const DreamsContentStateView(
              state: DreamsContentState.preparing,
              detail:
                  'El descifrador mostrará únicamente símbolos respaldados por contenido autorizado.',
            )
          else if (_controller.text.trim().isEmpty)
            const DreamsContentStateView(
              state: DreamsContentState.noResults,
              detail: 'Escribe una descripción antes de iniciar el análisis.',
            )
          else if (widget.catalog == null)
            const DreamsContentStateView(
              state: DreamsContentState.noAuthorizedContent,
              detail:
                  'No existe un catálogo autorizado disponible. No se generaron asociaciones ni números.',
            )
          else if (result == null || result.matches.isEmpty)
            const DreamsContentStateView(
              state: DreamsContentState.noResults,
              detail:
                  'No reconocimos símbolos documentados. No se generaron interpretaciones ni números.',
            )
          else
            ...result.matches.map((match) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.entry.canonicalTerm,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text('Fragmento: “${match.fragment}”'),
                        Text(match.negated
                            ? 'El fragmento está negado; no activa asociaciones.'
                            : match.claims.isEmpty
                                ? 'Sin asociaciones numéricas autorizadas.'
                                : 'Números documentados: ${match.claims.map((claim) => claim.number).join(', ')}'),
                        if (match.ambiguous)
                          const Text('Esta expresión puede ser ambigua.'),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 12),
          const Text(
            'Tu relato no se envía a servidores ni se almacena por esta herramienta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
