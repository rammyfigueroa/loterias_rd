import 'package:flutter/material.dart';

/// A row of feature highlights shown on the home page. Each feature has an
/// icon, a title and a subtitle. The items are evenly spaced across the
/// available width.
class QuickFeatures extends StatelessWidget {
  final VoidCallback? onTapFavorites;
  final VoidCallback? onTapShare;

  const QuickFeatures({super.key, this.onTapFavorites, this.onTapShare});

  @override
  Widget build(BuildContext context) {
    Widget _buildItem({
      required IconData icon,
      required String title,
      required String subtitle,
      VoidCallback? onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF003893)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF003893),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildItem(
              icon: Icons.flash_on,
              title: 'Rápido',
              subtitle: 'Resultados al instante',
              onTap: null,
            ),
          ),
          Expanded(
            child: _buildItem(
              icon: Icons.check_circle_outline,
              title: 'Confiable',
              subtitle: 'Datos verificados',
              onTap: null,
            ),
          ),
          Expanded(
            child: _buildItem(
              icon: Icons.star_border,
              title: 'Favoritas',
              subtitle: 'Guarda y accede',
              onTap: onTapFavorites,
            ),
          ),
          Expanded(
            child: _buildItem(
              icon: Icons.share,
              title: 'Comparte',
              subtitle: 'Envía a tus amigos',
              onTap: onTapShare,
            ),
          ),
        ],
      ),
    );
  }
}