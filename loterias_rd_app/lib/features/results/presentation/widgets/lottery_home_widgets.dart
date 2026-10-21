import 'package:flutter/material.dart';

import '../../../../domain/lottery_result.dart';
import '../../application/lottery_catalog.dart';
import 'lottery_icon.dart';

class LotterySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const LotterySearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar lotería, fecha o número...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  focusNode.requestFocus();
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF89BFFF), width: 1.5),
        ),
      ),
    );
  }
}

class LotteryFilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const LotteryFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const filters = <(String, IconData)>[
      ('Todas', Icons.apps),
      ('Favoritas', Icons.star_outline),
      ('Recientes', Icons.schedule),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;
        final itemSpacing = compact ? 4.0 : 8.0;
        final iconSize = compact ? 15.0 : 17.0;
        final labelSpacing = compact ? 4.0 : 6.0;
        final fontSize = compact ? 11.5 : 13.0;
        return Row(
          children: List.generate(filters.length, (index) {
            final filter = filters[index];
            final isSelected = selected == filter.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == filters.length - 1 ? 0 : itemSpacing,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0B6FF4) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0B6FF4)
                          : const Color(0xFFE7EDF5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0x260B6FF4)
                            : const Color(0x0D17345C),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(filter.$1),
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              filter.$2,
                              size: iconSize,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4B5E78),
                            ),
                            SizedBox(width: labelSpacing),
                            Flexible(
                              child: Text(
                                filter.$1,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1C2C43),
                                  fontWeight: FontWeight.w800,
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class LotteryVisualStyle {
  final Color accentColor;
  final Color backgroundAccent;

  const LotteryVisualStyle({
    required this.accentColor,
    required this.backgroundAccent,
  });

  static LotteryVisualStyle forName(String lotteryName) {
    final name = normalizeLotteryText(lotteryName);
    if (name.contains('anguila')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFFE6A900),
        backgroundAccent: Color(0xFFFFF6D7),
      );
    }
    if (name.contains('haiti') || name.contains('bolet')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFF0B56B5),
        backgroundAccent: Color(0xFFE8F2FF),
      );
    }
    if (name.contains('americana') || name.contains('florida')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFFE98916),
        backgroundAccent: Color(0xFFFFF0DD),
      );
    }
    if (name.contains('king')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFFD6A500),
        backgroundAccent: Color(0xFFFFF6CF),
      );
    }
    if (name.contains('primera')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFFE9273B),
        backgroundAccent: Color(0xFFFFE9EC),
      );
    }
    if (name.contains('suerte')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFFCE2943),
        backgroundAccent: Color(0xFFF4ECF5),
      );
    }
    if (name.contains('leidsa')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFF1648A0),
        backgroundAccent: Color(0xFFEAF1FF),
      );
    }
    if (name.contains('lotedom')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFF384CBD),
        backgroundAccent: Color(0xFFEEEFFF),
      );
    }
    if (name.contains('loteka')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFF0095D7),
        backgroundAccent: Color(0xFFE3F6FF),
      );
    }
    if (name.contains('nacional')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFF218A47),
        backgroundAccent: Color(0xFFE7F6EC),
      );
    }
    if (name.contains('real')) {
      return const LotteryVisualStyle(
        accentColor: Color(0xFF188C72),
        backgroundAccent: Color(0xFFE4F5F1),
      );
    }
    return const LotteryVisualStyle(
      accentColor: Color(0xFF0B6FF4),
      backgroundAccent: Color(0xFFEAF3FF),
    );
  }
}

class LotteryCard extends StatefulWidget {
  final LotteryGroup group;
  final bool isFavorite;
  final bool hasResultsToday;
  final VoidCallback onTap;

  const LotteryCard({
    super.key,
    required this.group,
    required this.isFavorite,
    this.hasResultsToday = false,
    required this.onTap,
  });

  @override
  State<LotteryCard> createState() => _LotteryCardState();
}

class _LotteryCardState extends State<LotteryCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final style = LotteryVisualStyle.forName(widget.group.name);
    return Semantics(
      button: true,
      label: 'Abrir resultados de ${widget.group.name}',
      child: AnimatedScale(
        scale: _pressed ? .975 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: widget.hasResultsToday
                ? Border.all(color: const Color(0xFF16A34A), width: 1.7)
                : null,
            boxShadow: [
              const BoxShadow(
                color: Color(0x141B3555),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
              if (widget.hasResultsToday)
                const BoxShadow(
                  color: Color(0x4016A34A),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              splashColor: style.accentColor.withValues(alpha: .08),
              highlightColor: style.accentColor.withValues(alpha: .04),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  style.backgroundAccent,
                                  Color.lerp(
                                    style.backgroundAccent,
                                    Colors.white,
                                    .56,
                                  )!,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: -12,
                            bottom: -25,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: style.accentColor.withValues(alpha: .07),
                              ),
                            ),
                          ),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: .84,
                              heightFactor: .78,
                              child: LotteryIcon(
                                lotteryName: widget.group.name,
                                size: 92,
                              ),
                            ),
                          ),
                          if (widget.hasResultsToday)
                            Positioned(
                              left: 5,
                              top: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x3316A34A),
                                      blurRadius: 7,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Hoy',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (widget.isFavorite)
                            Positioned(
                              left: 8,
                              top: widget.hasResultsToday ? null : 8,
                              bottom: widget.hasResultsToday ? 8 : null,
                              child: const Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: Color(0xFFF2B400),
                              ),
                            ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 31,
                              height: 31,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .88),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x101B3555),
                                    blurRadius: 7,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                size: 17,
                                color: style.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      widget.group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF081426),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.group.results.length} ${widget.group.results.length == 1 ? 'sorteo' : 'sorteos'}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF718096),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResultNumberBalls extends StatelessWidget {
  final LotteryResult result;
  final double size;
  final double spacing;
  final WrapAlignment alignment;

  const ResultNumberBalls({
    super.key,
    required this.result,
    this.size = 42,
    this.spacing = 7,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final numbers = resultNumbers(result);
    return Wrap(
      alignment: alignment,
      runAlignment: alignment,
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(numbers.length, (index) {
        final colors = <Color>[
          const Color(0xFF0648A8),
          const Color(0xFFF8FAFC),
          const Color(0xFFE51D35),
        ];
        final background = colors[index % colors.length];
        final foreground =
            index % colors.length == 1 ? const Color(0xFF0F172A) : Colors.white;
        return Container(
          key: ValueKey('result-ball-$index'),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: Border.all(color: const Color(0xFFDCE4EF), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F0F172A),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                numbers[index],
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  fontSize: size * .44,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class RecentResultCard extends StatelessWidget {
  final LotteryResult result;
  final VoidCallback onTap;

  const RecentResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  String? get _time {
    return RegExp(r'\b\d{1,2}:\d{2}\s*(?:AM|PM)\b', caseSensitive: false)
        .firstMatch(result.drawName)
        ?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121B3555),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: LotteryIcon(lotteryName: result.lotteryName, size: 38),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.lotteryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          formatDrawDateDayFirst(result.drawDate),
                          if (_time != null) _time!,
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                      const SizedBox(height: 11),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isShort = hasShortVisibleNumberGroup(result);
                          final spacing = isShort ? 8.0 : 7.0;
                          final ballSize = responsiveShortGroupBallSize(
                            result: result,
                            availableWidth: constraints.maxWidth,
                            spacing: spacing,
                            standardSize: 39,
                            maximumShortSize: 64,
                          );
                          return SizedBox(
                            width: double.infinity,
                            child: ResultNumberBalls(
                              result: result,
                              size: ballSize,
                              spacing: spacing,
                              alignment: isShort
                                  ? WrapAlignment.center
                                  : WrapAlignment.start,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F5FB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF315A8C),
                      size: 21,
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

class ResultsEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const ResultsEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
