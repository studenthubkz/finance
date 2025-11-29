import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  
  // In-memory storage for web
  static final List<Expense> _webExpenses = [];
  static final Set<String> _webProcessedHashes = {};

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite not supported on web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        dateTime INTEGER NOT NULL,
        category INTEGER NOT NULL,
        description TEXT,
        notificationHash TEXT,
        isAutoDetected INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_expenses_datetime ON expenses(dateTime)
    ''');

    await db.execute('''
      CREATE INDEX idx_expenses_hash ON expenses(notificationHash)
    ''');
    
    // Таблица для хранения обработанных хешей уведомлений
    await db.execute('''
      CREATE TABLE processed_notifications (
        hash TEXT PRIMARY KEY,
        processedAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS processed_notifications (
          hash TEXT PRIMARY KEY,
          processedAt INTEGER NOT NULL
        )
      ''');
    }
  }

  // CRUD операции для расходов
  Future<int> insertExpense(Expense expense) async {
    if (kIsWeb) {
      _webExpenses.insert(0, expense);
      return 1;
    }
    final db = await database;
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
    int? limit,
    int? offset,
  }) async {
    if (kIsWeb) {
      var filtered = _webExpenses.toList();
      if (startDate != null) {
        filtered = filtered.where((e) => e.dateTime.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        filtered = filtered.where((e) => e.dateTime.isBefore(endDate)).toList();
      }
      if (category != null) {
        filtered = filtered.where((e) => e.category == category).toList();
      }
      filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      if (offset != null && offset > 0) {
        filtered = filtered.skip(offset).toList();
      }
      if (limit != null) {
        filtered = filtered.take(limit).toList();
      }
      return filtered;
    }
    
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'dateTime >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'dateTime <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category.index);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'dateTime DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<Expense?> getExpenseById(String id) async {
    if (kIsWeb) {
      try {
        return _webExpenses.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  Future<int> updateExpense(Expense expense) async {
    if (kIsWeb) {
      final index = _webExpenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _webExpenses[index] = expense;
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    if (kIsWeb) {
      final lengthBefore = _webExpenses.length;
      _webExpenses.removeWhere((e) => e.id == id);
      return lengthBefore - _webExpenses.length;
    }
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllExpenses() async {
    if (kIsWeb) {
      final count = _webExpenses.length;
      _webExpenses.clear();
      return count;
    }
    final db = await database;
    return await db.delete('expenses');
  }

  // Статистика
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      var filtered = _webExpenses.toList();
      if (startDate != null) {
        filtered = filtered.where((e) => e.dateTime.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        filtered = filtered.where((e) => e.dateTime.isBefore(endDate)).toList();
      }
      double total = 0;
      for (final e in filtered) {
        total += e.amount;
      }
      return total;
    }
    
    final db = await database;
    
    String query = 'SELECT SUM(amount) as total FROM expenses';
    List<dynamic> args = [];

    if (startDate != null || endDate != null) {
      query += ' WHERE';
      if (startDate != null) {
        query += ' dateTime >= ?';
        args.add(startDate.millisecondsSinceEpoch);
      }
      if (endDate != null) {
        if (startDate != null) query += ' AND';
        query += ' dateTime <= ?';
        args.add(endDate.millisecondsSinceEpoch);
      }
    }

    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<ExpenseCategory, double>> getExpensesByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      var filtered = _webExpenses.toList();
      if (startDate != null) {
        filtered = filtered.where((e) => e.dateTime.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        filtered = filtered.where((e) => e.dateTime.isBefore(endDate)).toList();
      }
      Map<ExpenseCategory, double> categoryTotals = {};
      for (final expense in filtered) {
        categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
      return categoryTotals;
    }
    
    final db = await database;
    
    String query = 'SELECT category, SUM(amount) as total FROM expenses';
    List<dynamic> args = [];

    if (startDate != null || endDate != null) {
      query += ' WHERE';
      if (startDate != null) {
        query += ' dateTime >= ?';
        args.add(startDate.millisecondsSinceEpoch);
      }
      if (endDate != null) {
        if (startDate != null) query += ' AND';
        query += ' dateTime <= ?';
        args.add(endDate.millisecondsSinceEpoch);
      }
    }
    
    query += ' GROUP BY category ORDER BY total DESC';

    final result = await db.rawQuery(query, args);
    
    Map<ExpenseCategory, double> categoryTotals = {};
    for (final row in result) {
      final category = ExpenseCategory.values[row['category'] as int];
      categoryTotals[category] = (row['total'] as num).toDouble();
    }
    
    return categoryTotals;
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (kIsWeb) {
      Map<String, double> dailyTotals = {};
      
      // Инициализируем все даты в диапазоне нулями
      DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      while (!current.isAfter(end)) {
        final dateStr = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        dailyTotals[dateStr] = 0;
        current = current.add(const Duration(days: 1));
      }
      
      // Добавляем расходы
      for (final expense in _webExpenses) {
        if (!expense.dateTime.isBefore(startDate) && !expense.dateTime.isAfter(endDate)) {
          final dateStr = '${expense.dateTime.year}-${expense.dateTime.month.toString().padLeft(2, '0')}-${expense.dateTime.day.toString().padLeft(2, '0')}';
          dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0) + expense.amount;
        }
      }
      return dailyTotals.entries
          .map((e) => {'date': e.key, 'total': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    }
    
    final db = await database;
    
    // Получаем расходы из БД
    final result = await db.rawQuery('''
      SELECT 
        DATE(dateTime / 1000, 'unixepoch', 'localtime') as date,
        SUM(amount) as total
      FROM expenses
      WHERE dateTime >= ? AND dateTime <= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]);

    // Преобразуем в map для быстрого доступа
    Map<String, double> expensesByDate = {};
    for (final row in result) {
      expensesByDate[row['date'] as String] = (row['total'] as num).toDouble();
    }

    // Генерируем все даты в диапазоне
    List<Map<String, dynamic>> dailyData = [];
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    while (!current.isAfter(end)) {
      final dateStr = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      dailyData.add({
        'date': dateStr,
        'total': expensesByDate[dateStr] ?? 0.0,
      });
      current = current.add(const Duration(days: 1));
    }

    return dailyData;
  }

  // Проверка дубликатов
  Future<bool> isNotificationProcessed(String hash) async {
    if (kIsWeb) {
      return _webProcessedHashes.contains(hash);
    }
    final db = await database;
    final result = await db.query(
      'processed_notifications',
      where: 'hash = ?',
      whereArgs: [hash],
    );
    return result.isNotEmpty;
  }

  Future<void> markNotificationProcessed(String hash) async {
    if (kIsWeb) {
      _webProcessedHashes.add(hash);
      return;
    }
    final db = await database;
    await db.insert(
      'processed_notifications',
      {
        'hash': hash,
        'processedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Очистка старых записей о обработанных уведомлениях (старше 7 дней)
  Future<void> cleanupOldNotificationHashes() async {
    if (kIsWeb) {
      // For web, just keep the set as is (it's session-based anyway)
      return;
    }
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    await db.delete(
      'processed_notifications',
      where: 'processedAt < ?',
      whereArgs: [sevenDaysAgo.millisecondsSinceEpoch],
    );
  }
}
