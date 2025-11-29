import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class CategoryChart extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryTotals;

  const CategoryChart({
    super.key,
    required this.categoryTotals,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final settings = context.read<SettingsProvider>();
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Показываем только топ-5 категорий
    final topCategories = sortedCategories.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Прогресс-бар с категориями
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: sortedCategories.map((entry) {
                  final percent = entry.value / total;
                  return Expanded(
                    flex: (percent * 100).round().clamp(1, 100),
                    child: Container(color: entry.key.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Легенда
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: topCategories.map((entry) {
              final percent = (entry.value / total * 100).toStringAsFixed(0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.key.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key.name} $percent%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
