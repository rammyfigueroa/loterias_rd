import 'package:flutter/material.dart';

// This widget lives in lib/features/results/presentation/widgets, so we need
// to ascend four directories to reach lib/data and lib/domain.
import '../../../../data/favorites_repository.dart';
import '../../../../domain/lottery_result.dart';
import '../result_detail_page.dart';
import 'horizontal_result_balls.dart';
import 'lottery_icon.dart';
import 'three_prize_balls.dart';

/// A compact card displaying basic information about a lottery draw.
///
/// The card keeps the lottery name, date and prize ball size visible, but
/// reduces vertical spacing so more results fit on screen. A small status dot
/// beside the favourite icon indicates freshness: green for today's results
/// and grey for previous-day results.
class LotteryResultCard extends StatefulWidget {
  final LotteryResult result;
  final FavoritesRepository favoritesRepository;

  const LotteryResultCard({
    super.key,
    required this.result,
    required this.favoritesRepository,
  });

  @override
  State<LotteryResultCard> createState() => _LotteryResultCardState();
}

class _LotteryResultCardState extends State<LotteryResultCard> {
  static const Color _todayPositionLabelColor = Color(0xFF16A34A);
  static const Color _previousPositionLabelColor = Color(0xFF8A94A6);

  bool _isFavorite = false;

  String get _id =>
      '${widget.result.lotteryName}_${widget.result.drawName}_${widget.result.drawDate}';

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final isFav = await widget.favoritesRepository.isFavorite(_id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    await widget.favoritesRepository.toggleFavorite(_id);
    final isFav = await widget.favoritesRepository.isFavorite(_id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  DateTime? _parseDrawDate(String rawDate) {
    final value = rawDate.trim();
    if (value.isEmpty) return null;

    // Handles YYYY-MM-DD and ISO strings like 2026-05-30T17:54:33.742.
    final isoCandidate = value.length >= 10 ? value.substring(0, 10) : value;
    final isoDate = DateTime.tryParse(isoCandidate);
    if (isoDate != null) return isoDate;

    DateTime? safeDate(int year, int month, int day) {
      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
      return null;
    }

    // Handles DD/MM/YYYY and DD-MM-YYYY.
    final slashOrDash = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$');
    final match = slashOrDash.firstMatch(value);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      if (day != null && month != null && year != null) {
        return safeDate(year, month, day);
      }
    }

    // Handles short local dates like 29-06 or 29/06.
    final shortDate = RegExp(r'^(\d{1,2})[/-](\d{1,2})(?:\b|$)');
    final shortMatch = shortDate.firstMatch(value);
    if (shortMatch != null) {
      final now = DateTime.now();
      final day = int.tryParse(shortMatch.group(1)!);
      final month = int.tryParse(shortMatch.group(2)!);
      if (day != null && month != null) {
        return safeDate(now.year, month, day);
      }
    }

    return null;
  }

  bool get _isTodayResult {
    final drawDate = _parseDrawDate(widget.result.drawDate);
    if (drawDate == null) return false;
    final now = DateTime.now();
    return drawDate.year == now.year &&
        drawDate.month == now.month &&
        drawDate.day == now.day;
  }

  Color get _statusColor =>
      _isTodayResult ? const Color(0xFF22C55E) : Colors.grey.shade500;

  Color get _positionLabelColor =>
      _isTodayResult ? _todayPositionLabelColor : _previousPositionLabelColor;

  List<String> get _displayNumbers {
    if (widget.result.prizes.isNotEmpty) {
      return widget.result.prizes.map((prize) => prize.number).toList();
    }
    return widget.result.numbers;
  }

  List<String> get _displayLabels {
    if (widget.result.prizes.isEmpty) {
      return const ['1ro', '2do', '3ro'];
    }

    return List<String>.generate(widget.result.prizes.length, (index) {
      final prize = widget.result.prizes[index];
      final position = prize.position > 0 ? prize.position : index + 1;
      if (position == 1) return '1ro';
      if (position == 2) return '2do';
      if (position == 3) return '3ro';
      if (prize.label.trim().isNotEmpty) return prize.label.trim();
      return '${position}to';
    });
  }

  @override
  Widget build(BuildContext context) {
    final numbers = _displayNumbers;

    return Card(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultDetailPage(result: widget.result),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            16,
            18,
            numbers.length > 5 ? 22 : 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LotteryIcon(
                    lotteryName: widget.result.lotteryName,
                    size: 48,
                    color: const Color(0xFF003893),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.result.drawName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.result.drawDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _statusColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleFavorite,
                    iconSize: 34,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: Icon(
                      _isFavorite ? Icons.star : Icons.star_border,
                      color: _isFavorite
                          ? const Color(0xFF003893)
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              numbers.length <= 3
                  ? ThreePrizeBalls(
                      numbers: numbers,
                      labels: _displayLabels,
                      maxSize: 88,
                      labelColor: _positionLabelColor,
                    )
                  : HorizontalResultBalls(numbers: numbers, size: 56),
            ],
          ),
        ),
      ),
    );
  }
}
