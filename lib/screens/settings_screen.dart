import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final BackupService _backupService = BackupService();
  bool _hasNotificationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _notificationService.hasPermission();
    setState(() => _hasNotificationPermission = hasPermission);
  }

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
              _buildTestNotificationSection(context),
              const SizedBox(height: 16),
              _buildNotificationSection(context),
              const SizedBox(height: 16),
              _buildBudgetSection(context),
              const SizedBox(height: 16),
              _buildCurrencySection(context),
              const SizedBox(height: 16),
              _buildBackupSection(context),
              const SizedBox(height: 16),
              _buildAboutSection(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Настройки',
      style: Theme.of(context).textTheme.displaySmall,
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildTestNotificationSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Тестирование',
      icon: Icons.science_rounded,
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment_rounded,
              color: AppTheme.accentColor,
            ),
          ),
          title: const Text('Имитировать Google Pay'),
          subtitle: const Text('Создать тестовый расход'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showTestNotificationDialog(context),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.successColor,
            ),
          ),
          title: const Text('Случайный расход'),
          subtitle: const Text('Добавить случайную покупку'),
          trailing: ElevatedButton(
            onPressed: () => _addRandomExpense(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Добавить'),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 50.ms);
  }

  void _showTestNotificationDialog(BuildContext context) {
    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    final settings = context.read<SettingsProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment_rounded, color: AppTheme.accentColor),
            SizedBox(width: 12),
            Text('Имитация Google Pay'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Сумма',
                hintText: '1500',
                suffixText: settings.currency,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: merchantController,
              decoration: const InputDecoration(
                labelText: 'Магазин',
                hintText: 'Magnum',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              final merchant = merchantController.text.isEmpty
                  ? 'Тестовый магазин'
                  : merchantController.text;
              
              if (amount > 0) {
                _simulateGooglePayNotification(context, amount, merchant);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateGooglePayNotification(
    BuildContext context,
    double amount,
    String merchant,
  ) async {
    await _notificationService.simulateNotification(
      amount: amount,
      merchant: merchant,
    );
    
    // Перезагружаем расходы
    if (context.mounted) {
      await context.read<ExpenseProvider>().loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.successColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Добавлен расход: ${amount.toStringAsFixed(0)} ${context.read<SettingsProvider>().currency} в $merchant',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addRandomExpense(BuildContext context) async {
    final random = Random();
    final merchants = [
      'Magnum',
      'Small',
      'Arbuz.kz',
      'Glovo',
      'Wolt',
      'Kaspi Магазин',
      'Sulpak',
      'Technodom',
      'Marwin',
      'Burger King',
      'KFC',
      'Starbucks',
      'Chocolife',
      'Yandex Go',
      'InDriver',
    ];
    
    final amounts = [500, 1200, 2500, 3800, 5000, 7500, 12000, 15000, 25000];
    
    final merchant = merchants[random.nextInt(merchants.length)];
    final amount = amounts[random.nextInt(amounts.length)].toDouble();
    
    await _simulateGooglePayNotification(context, amount, merchant);
  }

  Widget _buildNotificationSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Уведомления',
      icon: Icons.notifications_rounded,
      children: [
        _buildPermissionTile(context),
        const Divider(height: 1),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return _buildSwitchTile(
              context,
              title: 'Отслеживать Google Pay',
              subtitle: 'Автоматически добавлять расходы',
              value: settings.notificationsEnabled,
              onChanged: (value) => settings.setNotificationsEnabled(value),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildPermissionTile(BuildContext context) {
    return ListTile(
      title: const Text('Доступ к уведомлениям'),
      subtitle: Text(
        _hasNotificationPermission ? 'Разрешено' : 'Требуется разрешение',
        style: TextStyle(
          color: _hasNotificationPermission
              ? AppTheme.successColor
              : AppTheme.warningColor,
        ),
      ),
      trailing: _hasNotificationPermission
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.successColor)
          : ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Разрешить'),
            ),
    );
  }

  Future<void> _requestPermission() async {
    await _notificationService.requestPermission();
    await _checkPermission();
  }

  Widget _buildBudgetSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildSection(
          context,
          title: 'Бюджет',
          icon: Icons.account_balance_wallet_rounded,
          children: [
            ListTile(
              title: const Text('Месячный бюджет'),
              subtitle: Text(
                settings.monthlyBudget > 0
                    ? settings.formatAmountFull(settings.monthlyBudget)
                    : 'Не установлен',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showBudgetDialog(context, settings),
            ),
          ],
        );
      },
    ).animate().fadeIn(delay: 200.ms);
  }

  void _showBudgetDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(
      text: settings.monthlyBudget > 0
          ? settings.monthlyBudget.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Месячный бюджет'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Введите сумму',
            suffixText: settings.currency,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              settings.setMonthlyBudget(amount);
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return _buildSection(
          context,
          title: 'Валюта',
          icon: Icons.currency_exchange_rounded,
          children: [
            ListTile(
              title: const Text('Валюта'),
              subtitle: Text(_getCurrencyName(settings.currency)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showCurrencyDialog(context, settings),
            ),
          ],
        );
      },
    ).animate().fadeIn(delay: 300.ms);
  }

  String _getCurrencyName(String symbol) {
    switch (symbol) {
      case '₸':
        return 'Казахстанский тенге (₸)';
      case '₽':
        return 'Российский рубль (₽)';
      case '\$':
        return 'Доллар США (\$)';
      case '€':
        return 'Евро (€)';
      default:
        return symbol;
    }
  }

  void _showCurrencyDialog(BuildContext context, SettingsProvider settings) {
    final currencies = ['₸', '₽', '\$', '€'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите валюту'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            return ListTile(
              title: Text(_getCurrencyName(currency)),
              trailing: settings.currency == currency
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                settings.setCurrency(currency);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'О приложении',
      icon: Icons.info_outline_rounded,
      children: [
        const ListTile(
          title: Text('Версия'),
          subtitle: Text('1.0.0'),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Как это работает'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showHowItWorksDialog(context),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildBackupSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Резервное копирование',
      icon: Icons.backup_rounded,
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          title: const Text('Экспорт данных'),
          subtitle: const Text('Сохранить в JSON файл'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _exportData(context),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.cloud_download_rounded,
              color: AppTheme.successColor,
            ),
          ),
          title: const Text('Импорт данных'),
          subtitle: const Text('Загрузить из JSON файла'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _importData(context),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_forever_rounded,
              color: AppTheme.errorColor,
            ),
          ),
          title: const Text('Удалить все данные'),
          subtitle: const Text('Очистить историю расходов'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _confirmClearData(context),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms);
  }

  Future<void> _exportData(BuildContext context) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final count = expenseProvider.expenses.length;
    
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет данных для экспорта'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final result = await _backupService.exportData();
    
    if (context.mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.successColor),
                const SizedBox(width: 12),
                Text('Экспортировано $count записей'),
              ],
            ),
            backgroundColor: AppTheme.cardColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка экспорта'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    final result = await _backupService.importData();
    
    if (context.mounted) {
      if (result > 0) {
        await context.read<ExpenseProvider>().loadExpenses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.successColor),
                const SizedBox(width: 12),
                Text('Импортировано $result записей'),
              ],
            ),
            backgroundColor: AppTheme.cardColor,
          ),
        );
      } else if (result == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Файл не выбран или пуст'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка импорта: неверный формат файла'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.errorColor),
            SizedBox(width: 12),
            Text('Удалить все данные?'),
          ],
        ),
        content: const Text(
          'Это действие нельзя отменить. Все ваши расходы будут удалены безвозвратно.\n\n'
          'Рекомендуем сначала сделать резервную копию.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await _backupService.clearAllData();
      if (success) {
        await context.read<ExpenseProvider>().loadExpenses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Все данные удалены'),
            backgroundColor: AppTheme.cardColor,
          ),
        );
      }
    }
  }

  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Как это работает'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Разрешите доступ к уведомлениям\n\n'
                '2. Приложение автоматически читает уведомления от Google Pay\n\n'
                '3. Когда вы оплачиваете покупку, расход автоматически добавляется в приложение\n\n'
                '4. Категория определяется автоматически по названию магазина\n\n'
                '5. Дубликаты уведомлений отфильтровываются',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Форматы уведомлений Google Pay:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• "₽1 234,56 в Магазин"\n'
                '• "Оплата 1234,56 ₽ в Магазин"\n'
                '• "\$12.34 at Store Name"',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
