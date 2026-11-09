import 'package:flutter/material.dart';

import 'dreams_content_state.dart';
import 'widgets/dreams_shared_widgets.dart';

class TraditionsBeliefsPage extends StatelessWidget {
  const TraditionsBeliefsPage({super.key});

  @override
  Widget build(BuildContext context) => const DreamsBranchScaffold(
        title: 'Tradiciones y Creencias',
        description:
            'Biblioteca cultural para artículos, referencias históricas y fuentes verificadas.',
        child: DreamsContentStateView(state: DreamsContentState.preparing),
      );
}

class DominicanVariantsPage extends StatelessWidget {
  const DominicanVariantsPage({super.key});

  @override
  Widget build(BuildContext context) => const DreamsBranchScaffold(
        title: 'Variantes y Expresiones',
        description:
            'Espacio para términos, variantes, relaciones semánticas y contexto dominicano documentado.',
        child: DreamsContentStateView(state: DreamsContentState.preparing),
      );
}

class DominicanNumerologyPage extends StatelessWidget {
  const DominicanNumerologyPage({super.key});

  @override
  Widget build(BuildContext context) => const DreamsBranchScaffold(
        title: 'Numerología Dominicana',
        description:
            'Sueños, suerte y asociaciones numéricas en la cultura dominicana.',
        showNotice: true,
        child: DreamsContentStateView(state: DreamsContentState.preparing),
      );
}
