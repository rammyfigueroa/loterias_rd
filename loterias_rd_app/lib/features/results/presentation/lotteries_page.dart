import 'package:flutter/material.dart';

/// A page allowing the user to select a lottery to filter results.
///
/// The list of available lotteries is passed in and the currently selected
/// lottery (if any) may be highlighted. Tapping a lottery name returns
/// that name to the calling page; tapping "Todas" returns an empty
/// string.
class LotteriesPage extends StatelessWidget {
  final List<String> lotteries;
  final String? selected;

  const LotteriesPage({super.key, required this.lotteries, this.selected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar lotería'),
      ),
      body: ListView.separated(
        itemCount: lotteries.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Option to clear the filter
            return ListTile(
              title: const Text('Todas'),
              onTap: () {
                Navigator.of(context).pop('');
              },
            );
          }
          final name = lotteries[index - 1];
          final isSelected = selected == name;
          return ListTile(
            title: Text(name),
            trailing: isSelected
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              Navigator.of(context).pop(name);
            },
          );
        },
      ),
    );
  }
}