import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardColorLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: expense.category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              expense.category.icon,
              color: expense.category.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.merchant,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      expense.category.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: expense.category.color,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(expense.dateTime),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (expense.isAutoDetected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: AppTheme.accentColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '-${settings.formatAmount(expense.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );

    if (onDismissed != null) {
      return Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: AppTheme.errorColor,
          ),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else {
      return DateFormat('d MMM', 'ru').format(dateTime);
    }
  }
}
