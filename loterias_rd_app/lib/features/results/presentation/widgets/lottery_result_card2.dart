import 'package:flutter/material.dart';

// This widget lives in lib/features/results/presentation/widgets, so we need
// to ascend four directories to reach lib/data and lib/domain.
import '../../../../data/favorites_repository.dart';
import '../../../../domain/lottery_result.dart';
import '../result_detail_page.dart';
import 'labeled_result_balls.dart';
import 'lottery_icon.dart';

/// A compact card displaying the most important lottery draw information.
///
/// This version uses only the direct draw name in the top line
/// (for example, "Quiniela Leidsa") to save vertical space. The broader
/// lottery family is still represented by the icon.
///
/// The date works as the freshness indicator:
/// - Green date = result from today.
/// - Grey date = previous result.
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

    // Handles DD/MM/YYYY and DD-MM-YYYY.
    final slashOrDash = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$');
    final match = slashOrDash.firstMatch(value);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
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

  Color get _dateColor {
    return _isTodayResult ? const Color(0xFF16A34A) : const Color(0xFF6B7280);
  }

  String _formatDrawDate(String rawDate) {
    final date = _parseDrawDate(rawDate);
    if (date == null) return rawDate;

    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();

    return '$day-$month-$year';
  }

  @override
  Widget build(BuildContext context) {
    final numbers = widget.result.numbers;
    final firstThree = numbers.take(3).toList();
    final extraCount = numbers.length > 3 ? numbers.length - 3 : 0;

    return Card(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
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
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LotteryIcon(
                    lotteryName: widget.result.lotteryName,
                    size: 42,
                    color: const Color(0xFF003893),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.result.drawName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      height: 1.08,
                                    ),
                          ),
                          const SizedBox(height: 6),
                          Tooltip(
                            message: _isTodayResult
                                ? 'Resultados del día actual'
                                : 'Resultados de un día anterior',
                            child: Text(
                              _formatDrawDate(widget.result.drawDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: _dateColor,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: IconButton(
                      onPressed: _toggleFavorite,
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 30,
                      ),
                      icon: Icon(
                        _isFavorite ? Icons.star : Icons.star_border,
                        color: _isFavorite
                            ? const Color(0xFF003893)
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  LabeledResultBalls(
                    numbers: firstThree,
                    size: 74,
                    expand: true,
                  ),
                  if (extraCount > 0)
                    Positioned(
                      right: 0,
                      top: 18,
                      child: _ExtraCountChip(count: extraCount),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraCountChip extends StatelessWidget {
  final int count;

  const _ExtraCountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF003893).withOpacity(0.18),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            offset: Offset(0, 2),
            color: Colors.black12,
          ),
        ],
      ),
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF003893),
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}
