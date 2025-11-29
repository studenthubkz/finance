import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<Expense> _expenses = [];
  bool _isLoading = false;
  double _totalExpenses = 0;
  Map<ExpenseCategory, double> _categoryTotals = {};
  
  // Фильтры
  DateTime? _startDate;
  DateTime? _endDate;
  ExpenseCategory? _selectedCategory;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  double get totalExpenses => _totalExpenses;
  Map<ExpenseCategory, double> get categoryTotals => _categoryTotals;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  ExpenseCategory? get selectedCategory => _selectedCategory;

  // Получить расходы за текущий месяц
  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _expenses.where((e) => e.dateTime.isAfter(startOfMonth)).toList();
  }

  // Получить расходы за сегодня
  List<Expense> get todayExpenses {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _expenses.where((e) => e.dateTime.isAfter(startOfDay)).toList();
  }

  double get todayTotal {
    return todayExpenses.fold(0, (sum, e) => sum + e.amount);
  }

  double get currentMonthTotal {
    return currentMonthExpenses.fold(0, (sum, e) => sum + e.amount);
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _expenses = await _dbService.getExpenses(
        startDate: _startDate,
        endDate: _endDate,
        category: _selectedCategory,
      );
      
      await _loadStatistics();
    } catch (e) {
      debugPrint('Ошибка загрузки расходов: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStatistics() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    _totalExpenses = await _dbService.getTotalExpenses(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    _categoryTotals = await _dbService.getExpensesByCategory(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _dbService.insertExpense(expense);
      _expenses.insert(0, expense);
      await _loadStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка добавления расхода: $e');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _dbService.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
      }
      await _loadStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка обновления расхода: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _dbService.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      await _loadStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка удаления расхода: $e');
    }
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadExpenses();
  }

  void setCategoryFilter(ExpenseCategory? category) {
    _selectedCategory = category;
    loadExpenses();
  }

  void clearFilters() {
    _startDate = null;
    _endDate = null;
    _selectedCategory = null;
    loadExpenses();
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    return await _dbService.getDailyExpenses(
      startDate: startDate,
      endDate: now,
    );
  }
}
