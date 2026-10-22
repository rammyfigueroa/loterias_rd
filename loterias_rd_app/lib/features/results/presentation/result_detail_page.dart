import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../data/favorites_repository.dart';
import '../../../domain/lottery_result.dart';
import '../application/lottery_catalog.dart';
import '../application/result_share_service.dart';
import 'widgets/horizontal_result_balls.dart';
import 'widgets/lottery_icon.dart';
import 'widgets/three_prize_balls.dart';

class ResultDetailPage extends StatefulWidget {
  final LotteryResult result;
  final DateTime? nowUtc;

  const ResultDetailPage({super.key, required this.result, this.nowUtc});

  @override
  State<ResultDetailPage> createState() => _ResultDetailPageState();
}

class _ResultDetailPageState extends State<ResultDetailPage>
    with WidgetsBindingObserver {
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  bool _isFavorite = false;
  late DateTime _nowUtc;
  Timer? _dayChangeTimer;

  String get _id =>
      '${widget.result.lotteryName}_${widget.result.drawName}_${widget.result.drawDate}';

  bool get _isThreeNumberDraw => resultNumbers(widget.result).length <= 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nowUtc = widget.nowUtc ?? DateTime.now().toUtc();
    _loadFavorite();
    _scheduleDayChangeRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayChangeTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDominicanDate();
  }

  void _refreshDominicanDate() {
    final nowUtc = DateTime.now().toUtc();
    if (mounted) setState(() => _nowUtc = nowUtc);
    _scheduleDayChangeRefresh(nowUtc: nowUtc);
  }

  void _scheduleDayChangeRefresh({DateTime? nowUtc}) {
    _dayChangeTimer?.cancel();
    final currentUtc = nowUtc ?? DateTime.now().toUtc();
    _dayChangeTimer = Timer(
      untilNextDominicanDay(currentUtc) + const Duration(seconds: 1),
      _refreshDominicanDate,
    );
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
    final isToday = isResultFromDominicanToday(
      widget.result,
      nowUtc: _nowUtc,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF003893),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004FCF),
        elevation: 0,
        centerTitle: true,
        title: const Text('Detalle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Favorito',
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
            colors: [Color(0xFF004FCF), Color(0xFF0052C4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.38, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailHeader(result: widget.result, nowUtc: _nowUtc),
                const SizedBox(height: 18),
                _NumbersCard(
                  result: widget.result,
                  isThreeNumberDraw: _isThreeNumberDraw,
                  isToday: isToday,
                ),
                const SizedBox(height: 18),
                Text(
                  'Estos resultados son informativos. Verifique siempre en la fuente oficial.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003893),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => shareLotteryResult(context, widget.result),
                  icon: const Icon(Icons.share),
                  label: const Text(
                    'Compartir resultado',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
  final DateTime nowUtc;

  const _DetailHeader({required this.result, required this.nowUtc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
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
                size: 38,
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
                  result.drawName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatDrawDateDayFirst(
                    result.drawDate,
                    now: dominicanCalendarDate(nowUtc),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumbersCard extends StatelessWidget {
  final LotteryResult result;
  final bool isThreeNumberDraw;
  final bool isToday;

  const _NumbersCard({
    required this.result,
    required this.isThreeNumberDraw,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        22,
        18,
        resultNumbers(result).length > 5 ? 30 : 26,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Colors.black26,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isThreeNumberDraw ? 'Premios' : 'Números del sorteo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 18),
          isThreeNumberDraw
              ? ThreePrizeBalls(
                  numbers: resultNumbers(result),
                  labels: result.prizes.isEmpty
                      ? null
                      : result.prizes.map((prize) => prize.label).toList(),
                  maxSize: 96,
                  labelColor: isToday
                      ? AppTheme.todayResultMetadataColor
                      : Colors.grey.shade600,
                )
              : HorizontalResultBalls(
                  numbers: resultNumbers(result),
                  size: 64,
                ),
        ],
      ),
    );
  }
}
