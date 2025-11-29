import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/expense.dart';
import 'database_service.dart';

/// Сервис для резервного копирования и восстановления данных
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// Экспортировать все расходы в JSON файл
  Future<String?> exportData() async {
    try {
      final expenses = await _dbService.getExpenses();
      
      if (expenses.isEmpty) {
        return null;
      }

      final data = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'expensesCount': expenses.length,
        'expenses': expenses.map((e) => {
          'id': e.id,
          'amount': e.amount,
          'merchant': e.merchant,
          'dateTime': e.dateTime.toIso8601String(),
          'category': e.category.index,
          'categoryName': e.category.name,
          'description': e.description,
          'isAutoDetected': e.isAutoDetected,
        }).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      if (kIsWeb) {
        // На веб просто возвращаем JSON
        return jsonStr;
      }

      // На мобильных сохраняем в файл
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'finance_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonStr);

      // Делимся файлом
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Резервная копия Финансы',
        text: 'Резервная копия данных приложения Финансы (${expenses.length} записей)',
      );

      return file.path;
    } catch (e) {
      debugPrint('BackupService: Export failed: $e');
      return null;
    }
  }

  /// Импортировать данные из JSON файла
  Future<int> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return 0;
      }

      String jsonStr;
      
      if (kIsWeb) {
        // На веб читаем bytes
        final bytes = result.files.first.bytes;
        if (bytes == null) return 0;
        jsonStr = utf8.decode(bytes);
      } else {
        // На мобильных читаем файл
        final path = result.files.first.path;
        if (path == null) return 0;
        final file = File(path);
        jsonStr = await file.readAsString();
      }

      return await importFromJson(jsonStr);
    } catch (e) {
      debugPrint('BackupService: Import failed: $e');
      return -1;
    }
  }

  /// Импортировать данные из JSON строки
  Future<int> importFromJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      if (!data.containsKey('expenses')) {
        return -1;
      }

      final expensesList = data['expenses'] as List;
      int imported = 0;

      for (final expenseData in expensesList) {
        try {
          final expense = Expense(
            id: expenseData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            amount: (expenseData['amount'] as num).toDouble(),
            merchant: expenseData['merchant'] as String,
            dateTime: DateTime.parse(expenseData['dateTime'] as String),
            category: ExpenseCategory.values[expenseData['category'] as int],
            description: expenseData['description'] as String?,
            isAutoDetected: expenseData['isAutoDetected'] as bool? ?? false,
          );

          await _dbService.insertExpense(expense);
          imported++;
        } catch (e) {
          debugPrint('BackupService: Failed to import expense: $e');
        }
      }

      return imported;
    } catch (e) {
      debugPrint('BackupService: Import from JSON failed: $e');
      return -1;
    }
  }

  /// Удалить все данные
  Future<bool> clearAllData() async {
    try {
      await _dbService.deleteAllExpenses();
      return true;
    } catch (e) {
      debugPrint('BackupService: Clear data failed: $e');
      return false;
    }
  }
}
