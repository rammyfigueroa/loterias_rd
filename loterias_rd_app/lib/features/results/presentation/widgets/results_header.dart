import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ResultsHeader extends StatelessWidget {
  const ResultsHeader({
    required this.totalResults,
    required this.loadedFromFallback,
    this.message,
    super.key,
  });

  final int totalResults;
  final bool loadedFromFallback;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.white.withOpacity(0.22)),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultados de hoy',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Loterias de Republica Dominicana',
                      style: TextStyle(color: Color(0xFFDCE8FF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeaderMetric(label: 'Sorteos', value: '$totalResults'),
              const SizedBox(width: 10),
              _HeaderMetric(
                label: 'Fuente',
                value: loadedFromFallback ? 'Muestra' : 'Web',
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: loadedFromFallback
                    ? AppTheme.red.withOpacity(0.18)
                    : AppTheme.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message!,
                style: const TextStyle(color: AppTheme.white, height: 1.25),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.blue,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
