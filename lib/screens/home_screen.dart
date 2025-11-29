import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/category_chart.dart';
import 'expenses_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = [
    const _HomeTab(),
    const ExpensesScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton(
              onPressed: () => _openAddExpense(context),
              child: const Icon(Icons.add_rounded),
            ).animate().scale(delay: 300.ms, duration: 300.ms)
          : null,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Главная'),
              _buildNavItem(1, Icons.receipt_long_rounded, 'Расходы'),
              _buildNavItem(2, Icons.bar_chart_rounded, 'Статистика'),
              _buildNavItem(3, Icons.settings_rounded, 'Настройки'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseScreen(),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  void _navigateToTab(BuildContext context, int index) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?.navigateToTab(index);
  }

  void _showTodayExpenses(BuildContext context, ExpenseProvider provider) {
    final today = DateTime.now();
    final todayExpenses = provider.expenses.where((e) {
      return e.dateTime.year == today.year &&
          e.dateTime.month == today.month &&
          e.dateTime.day == today.day;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TodayExpensesSheet(expenses: todayExpenses),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, SettingsProvider>(
      builder: (context, expenseProvider, settings, _) {
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildMainCard(context, expenseProvider, settings),
                      const SizedBox(height: 20),
                      _buildQuickStats(context, expenseProvider, settings),
                      const SizedBox(height: 24),
                      if (expenseProvider.categoryTotals.isNotEmpty) ...[
                        _buildCategorySection(context, expenseProvider),
                        const SizedBox(height: 24),
                      ],
                      _buildRecentSection(context, expenseProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Доброе утро';
    } else if (hour < 18) {
      greeting = 'Добрый день';
    } else {
      greeting = 'Добрый вечер';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.bodyMedium,
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'Финансы',
          style: Theme.of(context).textTheme.displayMedium,
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.1),
      ],
    );
  }

  Widget _buildMainCard(
    BuildContext context,
    ExpenseProvider provider,
    SettingsProvider settings,
  ) {
    final budgetPercent = settings.monthlyBudget > 0
        ? (provider.currentMonthTotal / settings.monthlyBudget * 100).clamp(0, 100)
        : 0.0;

    return GestureDetector(
      onTap: () => _navigateToTab(context, 2), // Переход в Статистику
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Расходы за месяц',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getCurrentMonth(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            settings.formatAmountFull(provider.currentMonthTotal),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (settings.monthlyBudget > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budgetPercent / 100,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  budgetPercent > 80 ? AppTheme.errorColor : Colors.white,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${budgetPercent.toStringAsFixed(0)}% от бюджета (${settings.formatAmountFull(settings.monthlyBudget)})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickStats(
    BuildContext context,
    ExpenseProvider provider,
    SettingsProvider settings,
  ) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Сегодня',
            value: settings.formatAmount(provider.todayTotal),
            icon: Icons.today_rounded,
            color: AppTheme.accentColor,
            onTap: () => _showTodayExpenses(context, provider),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            title: 'Транзакций',
            value: provider.currentMonthExpenses.length.toString(),
            icon: Icons.receipt_rounded,
            color: AppTheme.secondaryColor,
            onTap: () => _navigateToTab(context, 1), // Переход в Расходы
          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, ExpenseProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'По категориям',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        CategoryChart(categoryTotals: provider.categoryTotals),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildRecentSection(BuildContext context, ExpenseProvider provider) {
    final recentExpenses = provider.expenses.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Последние расходы',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (provider.expenses.length > 5)
              TextButton(
                onPressed: () => _navigateToTab(context, 1),
                child: const Text('Все'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentExpenses.isEmpty)
          _buildEmptyState(context)
        else
          ...recentExpenses.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ExpenseCard(
                    expense: entry.value,
                    onTap: () => _showExpenseDetails(context, entry.value),
                    onDismissed: () => _deleteExpense(context, entry.value),
                  )
                      .animate()
                      .fadeIn(delay: (600 + entry.key * 100).ms)
                      .slideX(begin: 0.1),
                ),
              ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardColorLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет расходов',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Расходы будут автоматически добавляться\nиз уведомлений Google Pay',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getCurrentMonth() {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[DateTime.now().month - 1];
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
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

class _TodayExpensesSheet extends StatelessWidget {
  final List<Expense> expenses;

  const _TodayExpensesSheet({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Расходы за сегодня',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  settings.formatAmountFull(total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Сегодня расходов нет!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: expenses.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExpenseCard(expense: expenses[index]),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
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
            SizedBox(
              width: double.infinity,
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

  void _deleteExpense(BuildContext context) {
    context.read<ExpenseProvider>().deleteExpense(expense.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Расход удалён')),
    );
  }
}
