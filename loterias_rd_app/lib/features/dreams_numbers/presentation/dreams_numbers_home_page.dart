import 'package:flutter/material.dart';

import '../application/publishable_catalog.dart';
import 'dream_dictionary_page.dart';
import 'dream_table_page.dart';
import 'dreams_placeholder_pages.dart';
import 'dream_decoder_page.dart';
import 'widgets/dreams_shared_widgets.dart';

class DreamsNumbersHomePage extends StatelessWidget {
  final PublishableCatalogResult catalogResult;

  const DreamsNumbersHomePage({
    super.key,
    this.catalogResult = const PublishableCatalogResult.unavailable(),
  });

  @override
  Widget build(BuildContext context) {
    final branches = <_DreamsBranch>[
      _DreamsBranch(
        title: 'Tabla Dominicana de Sueños',
        description:
            'Consulta las asociaciones tradicionales entre números y sueños.',
        icon: Icons.grid_view_rounded,
        page: DreamTablePage(catalog: catalogResult.catalog),
      ),
      _DreamsBranch(
        title: 'Diccionario de Sueños',
        description: 'Explora símbolos, significados y variantes documentadas.',
        icon: Icons.menu_book_outlined,
        page: DreamDictionaryPage(catalog: catalogResult.catalog),
      ),
      _DreamsBranch(
        title: 'Descifrador de Sueños',
        description:
            'Escribe lo que soñaste y descubre los elementos reconocidos.',
        icon: Icons.auto_awesome_outlined,
        page: DreamDecoderPage(catalog: catalogResult.catalog),
      ),
      const _DreamsBranch(
        title: 'Tradiciones y Creencias',
        description:
            'Conoce la historia y las creencias populares dominicanas.',
        icon: Icons.history_edu_outlined,
        page: TraditionsBeliefsPage(),
      ),
      const _DreamsBranch(
        title: 'Variantes y Expresiones',
        description:
            'Explora palabras, expresiones y asociaciones utilizadas en República Dominicana.',
        icon: Icons.forum_outlined,
        page: DominicanVariantsPage(),
      ),
      const _DreamsBranch(
        title: 'Numerología Dominicana',
        description:
            'Conoce las asociaciones numéricas populares documentadas en la cultura dominicana.',
        icon: Icons.numbers_rounded,
        page: DominicanNumerologyPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Sueños y Números Dominicanos')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 2 : 1;
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final cardHeight = (148 + (textScale - 1) * 64).clamp(148, 244);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        'Explora las tradiciones populares dominicanas relacionadas con los sueños y los números.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF52647C),
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const DreamsCulturalNotice(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: cardHeight.toDouble(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _BranchCard(branch: branches[index]),
                      childCount: branches.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final _DreamsBranch branch;

  const _BranchCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir ${branch.title}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => branch.page),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(branch.icon, color: const Color(0xFF0648A8)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        branch.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DreamsBranch {
  final String title;
  final String description;
  final IconData icon;
  final Widget page;

  const _DreamsBranch({
    required this.title,
    required this.description,
    required this.icon,
    required this.page,
  });
}
