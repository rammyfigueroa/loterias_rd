import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/lottery_result.dart';

class ResultDetailPage extends StatelessWidget {
  const ResultDetailPage({
    required this.result,
    required this.isFavorite,
    required this.onFavoriteToggle,
    super.key,
  });

  final LotteryResult result;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del sorteo'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
            onPressed: onFavoriteToggle,
            icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded),
          ),
          IconButton(
            tooltip: 'Compartir resultado',
            onPressed: () => Share.share(result.shareText),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.blue,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.lotteryName,
                  style: const TextStyle(
                    color: Color(0xFFDCE8FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.drawName,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppTheme.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      result.drawDate,
                      style: const TextStyle(color: AppTheme.white),
                    ),
                    if (result.isVerified) ...[
                      const SizedBox(width: 14),
                      const Icon(Icons.verified_rounded, color: AppTheme.white, size: 18),
                      const SizedBox(width: 6),
                      const Text('Verificado', style: TextStyle(color: AppTheme.white)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Numeros ganadores',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: result.numbers.map((number) {
              return _LargeNumberBall(number: number);
            }).toList(),
          ),
          if (result.prize != null) ...[
            const SizedBox(height: 22),
            _InfoTile(
              icon: Icons.payments_rounded,
              title: 'Premio acumulado',
              value: result.prize!,
            ),
          ],
          const SizedBox(height: 22),
          const _InfoTile(
            icon: Icons.info_rounded,
            title: 'Aviso importante',
            value: 'Estos resultados son informativos. Verifica siempre con la loteria oficial antes de reclamar premios.',
          ),
        ],
      ),
    );
  }
}

class _LargeNumberBall extends StatelessWidget {
  const _LargeNumberBall({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.red, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.red.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: AppTheme.red,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: AppTheme.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
