import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  ExpenseCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            _buildCategoryFilter(context),
            Expanded(child: _buildExpensesList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Все расходы',
        style: Theme.of(context).textTheme.displaySmall,
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Поиск по названию...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip(null, 'Все'),
          ...ExpenseCategory.values.map(
            (category) => _buildFilterChip(category, category.name),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFilterChip(ExpenseCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        backgroundColor: AppTheme.cardColor,
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        var expenses = provider.expenses;

        // Фильтрация по категории
        if (_selectedCategory != null) {
          expenses = expenses
              .where((e) => e.category == _selectedCategory)
              .toList();
        }

        // Фильтрация по поиску
        if (_searchQuery.isNotEmpty) {
          expenses = expenses
              .where((e) =>
                  e.merchant.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (expenses.isEmpty) {
          return _buildEmptyState(context);
        }

        // Группировка по датам
        final groupedExpenses = _groupExpensesByDate(expenses);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: groupedExpenses.length,
          itemBuilder: (context, index) {
            final dateGroup = groupedExpenses.entries.elementAt(index);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _formatDateHeader(dateGroup.key),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                ),
                ...dateGroup.value.map(
                  (expense) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExpenseCard(
                      expense: expense,
                      onTap: () => _showExpenseDetails(context, expense),
                      onDismissed: () => _deleteExpense(context, expense),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<DateTime, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final grouped = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final date = DateTime(
        expense.dateTime.year,
        expense.dateTime.month,
        expense.dateTime.day,
      );
      grouped.putIfAbsent(date, () => []).add(expense);
    }
    return grouped;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Сегодня';
    } else if (date == yesterday) {
      return 'Вчера';
    } else {
      return DateFormat('d MMMM', 'ru').format(date);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Ничего не найдено',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить параметры поиска',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExpenseDetailsSheet(expense: expense),
    );
  }

  void _deleteExpense(BuildContext context, Expense expense) {
    context.read<ExpenseProvider>().deleteExpense(expense.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Расход удалён'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            context.read<ExpenseProvider>().addExpense(expense);
          },
        ),
      ),
    );
  }
}

class _ExpenseDetailsSheet extends StatelessWidget {
  final Expense expense;

  const _ExpenseDetailsSheet({required this.expense});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(minHeight: 300),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: expense.category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    expense.category.icon,
                    color: expense.category.color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.merchant,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        expense.category.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              context,
              'Сумма',
              settings.formatAmountFull(expense.amount),
            ),
            _buildDetailRow(
              context,
              'Дата',
              DateFormat('d MMMM yyyy, HH:mm', 'ru').format(expense.dateTime),
            ),
            if (expense.isAutoDetected)
              _buildDetailRow(
                context,
                'Источник',
                'Google Pay (авто)',
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editExpense(context),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Изменить'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.cardColorLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteExpense(context),
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('Удалить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  void _editExpense(BuildContext context) {
    Navigator.pop(context);
    // TODO: Открыть экран редактирования
  }

  void _deleteExpense(BuildContext context) {
    context.read<ExpenseProvider>().deleteExpense(expense.id);
    Navigator.pop(context);
  }
}
