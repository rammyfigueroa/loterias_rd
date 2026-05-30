import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class LotteryFilterBar extends StatelessWidget {
  const LotteryFilterBar({
    required this.lotteries,
    required this.selectedLottery,
    required this.query,
    required this.onLotteryChanged,
    required this.onQueryChanged,
    super.key,
  });

  final List<String> lotteries;
  final String selectedLottery;
  final String query;
  final ValueChanged<String> onLotteryChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          TextField(
            onChanged: onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Buscar loteria, sorteo o numero',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lotteries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final lottery = lotteries[index];
                final selected = lottery == selectedLottery;
                return ChoiceChip(
                  label: Text(lottery),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppTheme.red,
                  backgroundColor: AppTheme.white,
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.white : AppTheme.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: selected ? AppTheme.red : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (_) => onLotteryChanged(lottery),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
