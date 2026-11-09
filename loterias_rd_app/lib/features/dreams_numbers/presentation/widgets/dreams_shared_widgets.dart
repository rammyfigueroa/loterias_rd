import 'package:flutter/material.dart';

import '../dreams_content_state.dart';

const dreamsCulturalNotice =
    'Las asociaciones entre sueños y números forman parte de tradiciones '
    'populares. No constituyen predicciones ni garantizan resultados.';

class DreamsCulturalNotice extends StatelessWidget {
  const DreamsCulturalNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Aclaración cultural',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB9D3F5)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Color(0xFF0648A8)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                dreamsCulturalNotice,
                style: TextStyle(color: Color(0xFF17345C), height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DreamsContentStateView extends StatelessWidget {
  final DreamsContentState state;
  final String? detail;
  final VoidCallback? onRetry;

  const DreamsContentStateView({
    super.key,
    required this.state,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(state);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE4EF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(presentation.icon, size: 40, color: const Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text(
              presentation.title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              detail ?? presentation.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5F6F86), height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar nuevamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatePresentation _presentationFor(DreamsContentState state) {
    return switch (state) {
      DreamsContentState.available => const _StatePresentation(
          Icons.check_circle_outline,
          'Contenido disponible',
          'La información fue verificada y autorizada para publicación.',
        ),
      DreamsContentState.noAuthorizedContent => const _StatePresentation(
          Icons.policy_outlined,
          'Sin contenido autorizado',
          'Todavía no hay información verificada y autorizada disponible.',
        ),
      DreamsContentState.preparing => const _StatePresentation(
          Icons.hourglass_top_rounded,
          'Contenido en preparación',
          'Estamos verificando las fuentes y asociaciones tradicionales para '
              'ofrecer información documentada sobre los sueños y números dominicanos.',
        ),
      DreamsContentState.loadError => const _StatePresentation(
          Icons.error_outline,
          'Error de carga',
          'No fue posible cargar el contenido autorizado.',
        ),
      DreamsContentState.noResults => const _StatePresentation(
          Icons.search_off,
          'Sin resultados',
          'No encontramos información documentada para esta consulta.',
        ),
      DreamsContentState.unverifiable => const _StatePresentation(
          Icons.fact_check_outlined,
          'Contenido no verificable',
          'La información disponible no cumple los controles documentales.',
        ),
    };
  }
}

class DreamsBranchScaffold extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;
  final bool showNotice;

  const DreamsBranchScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.showNotice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              description,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: const Color(0xFF52647C), height: 1.4),
            ),
            if (showNotice) ...[
              const SizedBox(height: 16),
              const DreamsCulturalNotice(),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatePresentation {
  final IconData icon;
  final String title;
  final String message;

  const _StatePresentation(this.icon, this.title, this.message);
}
