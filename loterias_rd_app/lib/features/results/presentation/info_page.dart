import 'package:flutter/material.dart';

/// A page that presents additional information about the app and its key features.
///
/// This page highlights why the app is fast, reliable, allows you to save
/// favourites, and makes it easy to share results with others. It is
/// accessible from the navigation drawer.
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
    required Color colour,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colour,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  color: Colors.black26,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de la app'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003893), Color(0xFF004fcf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Información general',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFeature(
                icon: Icons.flash_on,
                title: 'Rápido',
                description:
                    'Obtén los resultados de las sorteos dominicanos al instante en cuanto salen.',
                colour: const Color(0xFF003893),
              ),
              _buildFeature(
                icon: Icons.check_circle_outline,
                title: 'Confiable',
                description:
                    'Trabajamos con fuentes verificadas para que siempre tengas datos precisos y actualizados.',
                colour: const Color(0xFF004fcf),
              ),
              _buildFeature(
                icon: Icons.star_border,
                title: 'Favoritas',
                description:
                    'Guarda tus loterías o sorteos favoritos para consultarlos rápidamente.',
                colour: const Color(0xFFD90F2C),
              ),
              _buildFeature(
                icon: Icons.share,
                title: 'Comparte',
                description:
                    'Comparte fácilmente los resultados con amigos y familiares desde la app.',
                colour: Colors.green.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}