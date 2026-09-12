import 'package:flutter/material.dart';

import '../../../data/favorites_repository.dart';
import '../../../domain/lottery_result.dart';
import '../application/result_share_service.dart';
import 'widgets/lottery_icon.dart';

/// Detailed view for a lottery draw.
///
/// This version supports both standard 3-number lottery results and special
/// draws with 4, 5, or many numbers. The first three numbers remain prominent,
/// while additional numbers are shown in a clean wrap/grid below.
class ResultDetailPage extends StatefulWidget {
  final LotteryResult result;

  const ResultDetailPage({super.key, required this.result});

  @override
  State<ResultDetailPage> createState() => _ResultDetailPageState();
}

class _ResultDetailPageState extends State<ResultDetailPage> {
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  bool _isFavorite = false;

  String get _id =>
      '${widget.result.lotteryName}_${widget.result.drawName}_${widget.result.drawDate}';

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final isFav = await _favoritesRepository.isFavorite(_id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    await _favoritesRepository.toggleFavorite(_id);
    final isFav = await _favoritesRepository.isFavorite(_id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001B4D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001B4D), Color(0xFF003893), Color(0xFF001B4D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DetailHeader(result: widget.result),
                const SizedBox(height: 22),
                _DetailNumbersSection(numbers: widget.result.numbers),
                const SizedBox(height: 22),
                Text(
                  'Estos resultados son informativos.\nVerifique siempre en la fuente oficial.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => shareLotteryResult(context, widget.result),
                    icon: const Icon(Icons.share),
                    label: const Text(
                      'Compartir resultado',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final LotteryResult result;

  const _DetailHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 4),
                color: Colors.black26,
              ),
            ],
          ),
          child: Center(
            child: LotteryIcon(
              lotteryName: result.lotteryName,
              size: 34,
              color: const Color(0xFF003893),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.lotteryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                result.drawName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                result.drawDate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailNumbersSection extends StatelessWidget {
  final List<String> numbers;

  const _DetailNumbersSection({
    required this.numbers,
  });

  @override
  Widget build(BuildContext context) {
    final mainNumbers = numbers.take(3).toList();
    final extraNumbers = numbers.length > 3 ? numbers.skip(3).toList() : <String>[];

    return Column(
      children: [
        _MainNumbersPanel(
          numbers: mainNumbers,
          totalNumbers: numbers.length,
        ),
        if (extraNumbers.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ExtraNumbersPanel(numbers: extraNumbers),
        ],
      ],
    );
  }
}

class _MainNumbersPanel extends StatelessWidget {
  final List<String> numbers;
  final int totalNumbers;

  const _MainNumbersPanel({
    required this.numbers,
    required this.totalNumbers,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['PRIMERO', 'SEGUNDO', 'TERCERO'];
    final colors = [
      const Color(0xFF003893),
      const Color(0xFFF3F4F6),
      const Color(0xFFD90F2C),
    ];
    final textColors = [
      Colors.white,
      const Color(0xFF0F172A),
      Colors.white,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Colors.black26,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            totalNumbers > 3 ? 'Números principales' : 'Resultado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            totalNumbers > 3
                ? 'Mostrando los primeros 3 de $totalNumbers números'
                : 'Premios principales del sorteo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final number = index < numbers.length ? numbers[index] : '-';

              return Column(
                children: [
                  _DetailNumberBall(
                    number: number,
                    color: colors[index],
                    textColor: textColors[index],
                    addBorder: index == 1,
                    size: 78,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ExtraNumbersPanel extends StatelessWidget {
  final List<String> numbers;

  const _ExtraNumbersPanel({
    required this.numbers,
  });

  @override
  Widget build(BuildContext context) {
    final title = numbers.length > 6 ? 'Todos los números adicionales' : 'Números adicionales';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 5),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '+${numbers.length} número${numbers.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: numbers.map((number) {
              return _DetailNumberBall(
                number: number,
                color: const Color(0xFFEEF2FF),
                textColor: const Color(0xFF003893),
                addBorder: true,
                size: 48,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailNumberBall extends StatelessWidget {
  final String number;
  final Color color;
  final Color textColor;
  final bool addBorder;
  final double size;

  const _DetailNumberBall({
    required this.number,
    required this.color,
    required this.textColor,
    this.addBorder = false,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: addBorder
            ? Border.all(
                color: Colors.grey.shade300,
                width: 2,
              )
            : Border.all(
                color: Colors.white.withOpacity(0.75),
                width: 2,
              ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 4),
            color: Colors.black26,
          ),
        ],
      ),
      child: Text(
        number,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
