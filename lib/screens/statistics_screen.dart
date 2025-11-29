import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedPeriod = 0; // 0 = неделя, 1 = месяц, 2 = год

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildPeriodSelector(context),
              const SizedBox(height: 24),
              _buildLineChart(context),
              const SizedBox(height: 24),
              _buildPieChart(context),
              const SizedBox(height: 24),
              _buildCategoryList(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Статистика',
      style: Theme.of(context).textTheme.displaySmall,
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final periods = [
      ('Неделя', Icons.calendar_view_week_rounded),
      ('Месяц', Icons.calendar_view_month_rounded),
      ('Год', Icons.calendar_today_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardColorLight, width: 1),
      ),
      child: Row(
        children: periods.asMap().entries.map((entry) {
          final isSelected = _selectedPeriod == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedPeriod != entry.key) {
                  setState(() => _selectedPeriod = entry.key);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          entry.value.$2,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: isSelected ? 14 : 13,
                      ),
                      child: Text(entry.value.$1),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildLineChart(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<int>(_selectedPeriod),
            height: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Динамика расходов',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getPeriodLabel(),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: provider.getDailyExpenses(_getDaysForPeriod()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'Нет данных',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      return _buildChart(snapshot.data!);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 0:
        return 'Последние 7 дней';
      case 1:
        return 'Последние 30 дней';
      case 2:
        return 'Последний год';
      default:
        return '';
    }
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['total'] as num).toDouble(),
      );
    }).toList();

    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(spots),
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.cardColorLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getBottomInterval(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return const SizedBox();
                final date = data[value.toInt()]['date'] as String;
                return Text(
                  _formatChartDate(date),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.primaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppTheme.surfaceColor,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(0)} ₸',
                  const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1000;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return maxY > 0 ? maxY / 4 : 1000;
  }

  double _getBottomInterval() {
    switch (_selectedPeriod) {
      case 0:
        return 1;
      case 1:
        return 5;
      case 2:
        return 30;
      default:
        return 1;
    }
  }

  String _formatChartDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      switch (_selectedPeriod) {
        case 0:
          return DateFormat('E', 'ru').format(parsed).substring(0, 2);
        case 1:
          return DateFormat('d', 'ru').format(parsed);
        case 2:
          return DateFormat('MMM', 'ru').format(parsed).substring(0, 3);
        default:
          return '';
      }
    } catch (e) {
      return '';
    }
  }

  int _getDaysForPeriod() {
    switch (_selectedPeriod) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 365;
      default:
        return 7;
    }
  }

  Widget _buildPieChart(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final categoryTotals = provider.categoryTotals;
        if (categoryTotals.isEmpty) {
          return const SizedBox.shrink();
        }

        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'По категориям',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: categoryTotals.entries.map((entry) {
                      final percent = (entry.value / total * 100);
                      return PieChartSectionData(
                        value: entry.value,
                        title: '${percent.toStringAsFixed(0)}%',
                        color: entry.key.color,
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    return Consumer2<ExpenseProvider, SettingsProvider>(
      builder: (context, expenseProvider, settings, _) {
        final categoryTotals = expenseProvider.categoryTotals;
        if (categoryTotals.isEmpty) {
          return const SizedBox.shrink();
        }

        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Детализация',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...sortedCategories.asMap().entries.map((entry) {
                final category = entry.value.key;
                final amount = entry.value.value;
                final percent = amount / total;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  settings.formatAmount(amount),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: AppTheme.cardColorLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  category.color,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (400 + entry.key * 50).ms);
              }),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms);
      },
    );
  }
}
