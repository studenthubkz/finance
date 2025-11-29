import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _currencyKey = 'currency';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _monthlyBudgetKey = 'monthly_budget';

  String _currency = '₸';
  bool _notificationsEnabled = true;
  double _monthlyBudget = 0;

  String get currency => _currency;
  bool get notificationsEnabled => _notificationsEnabled;
  double get monthlyBudget => _monthlyBudget;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString(_currencyKey) ?? '₸';
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    _monthlyBudget = prefs.getDouble(_monthlyBudgetKey) ?? 0;
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_monthlyBudgetKey, budget);
    notifyListeners();
  }

  String formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $_currency';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K $_currency';
    }
    return '${amount.toStringAsFixed(2)} $_currency';
  }

  String formatAmountFull(double amount) {
    final formatted = amount.toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted $_currency';
  }
}
