import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/lottery_result.dart';

class LotteryResultCard extends StatelessWidget {
  const LotteryResultCard({
    required this.result,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    super.key,
  });

  final LotteryResult result;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LotteryBadge(label: result.lotteryName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.drawName,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: AppTheme.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.drawDate,
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                            if (result.isVerified) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppTheme.blue,
                              ),
                              const SizedBox(width: 4),
                              const Flexible(
                                child: Text(
                                  'Verificado',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppTheme.blue),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFavorite ? AppTheme.red : AppTheme.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: result.numbers.map((number) {
                  return _NumberBall(number: number);
                }).toList(),
              ),
              if (result.prize != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Premio acumulado: ${result.prize}',
                    style: const TextStyle(
                      color: AppTheme.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LotteryBadge extends StatelessWidget {
  const _LotteryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.blue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label.characters.take(2).toString().toUpperCase(),
        style: const TextStyle(
          color: AppTheme.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NumberBall extends StatelessWidget {
  const _NumberBall({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.red, width: 2),
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: AppTheme.red,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
