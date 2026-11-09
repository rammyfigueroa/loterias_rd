import 'package:flutter/material.dart';

import '../../../../app/app_features.dart';

class DreamsModulePromoCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const DreamsModulePromoCard({
    super.key,
    required this.onTap,
    this.enabled = AppFeatures.dreamsNumbersEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: 'Abrir Sueños y Números Dominicanos',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.nights_stay_outlined,
                    color: Color(0xFF0648A8),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sueños y Números Dominicanos',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Descubre los sueños, sus significados y las tradiciones numéricas de República Dominicana.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.3,
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

class DreamsDrawerTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const DreamsDrawerTile({
    super.key,
    required this.onTap,
    this.enabled = AppFeatures.dreamsNumbersEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: const Icon(Icons.nights_stay_outlined),
      title: const Text('Sueños y Números'),
      onTap: onTap,
    );
  }
}
