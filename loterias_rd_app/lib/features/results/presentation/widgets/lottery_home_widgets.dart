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
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter.$1;
          return FilterChip(
            avatar: Icon(filter.$2, size: 17),
            label: Text(filter.$1),
            selected: isSelected,
            onSelected: (_) => onSelected(filter.$1),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class LotteryCard extends StatelessWidget {
  final LotteryGroup group;
  final bool isFavorite;
  final VoidCallback onTap;

  const LotteryCard({
    super.key,
    required this.group,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir resultados de ${group.name}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    isFavorite ? Icons.star : Icons.arrow_outward,
                    size: 17,
                    color: isFavorite
                        ? const Color(0xFFF4B400)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: LotteryIcon(
                      lotteryName: group.name,
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${group.results.length} sorteos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
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

class ResultNumberBalls extends StatelessWidget {
  final LotteryResult result;
  final double size;

  const ResultNumberBalls({
    super.key,
    required this.result,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final numbers = resultNumbers(result);
    return Wrap(
      spacing: 7,
      runSpacing: 7,
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
                  fontSize: size * .39,
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
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 2),
                    Text(
                      result.drawName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF475569),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [result.drawDate, if (_time != null) _time!].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                    const SizedBox(height: 11),
                    ResultNumberBalls(result: result, size: 39),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              ),
            ],
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
