import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import 'database_service.dart';
import 'category_detector.dart';

/// Сервис для чтения и обработки уведомлений от Google Pay
/// 
/// Форматы уведомлений Google Pay:
/// 
/// Русский:
/// - Заголовок: "Оплата" / "Google Pay"
/// - Текст: "₽1 234,56 в Магазин" / "Оплата 1234,56 ₽ в Магазин"
/// - Текст: "Списано 1 234,56 ₽ в Магазин"
/// 
/// Английский:
/// - Заголовок: "Payment" / "Google Pay"
/// - Текст: "$12.34 at Store Name"
/// - Текст: "Paid $12.34 at Store Name"
/// 
/// ВАЖНО: Google Pay часто отправляет дублированные уведомления!
/// Используем хеширование для фильтрации дубликатов.
/// 
/// ПРИМЕЧАНИЕ: На веб-платформе этот сервис работает в демо-режиме.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DatabaseService _dbService = DatabaseService();
  final CategoryDetector _categoryDetector = CategoryDetector();
  
  Function(Expense)? _onExpenseDetected;
  
  // Пакеты Google Pay для разных регионов
  static const List<String> googlePayPackages = [
    'com.google.android.apps.walletnfcrel', // Google Pay (основной)
    'com.google.android.apps.nbu.paisa.user', // Google Pay (Индия)
    'com.google.android.gms', // Google Play Services (иногда используется)
  ];

  // Регулярные выражения для парсинга сумм
  static final List<RegExp> amountPatterns = [
    // Русский формат: ₽1 234,56 или 1 234,56 ₽
    RegExp(r'₽\s*([\d\s]+[,.]?\d*)', caseSensitive: false),
    RegExp(r'([\d\s]+[,.]?\d*)\s*₽', caseSensitive: false),
    RegExp(r'([\d\s]+[,.]?\d*)\s*(?:руб|рублей|р\.)', caseSensitive: false),
    
    // Доллары: $12.34
    RegExp(r'\$\s*([\d,]+\.?\d*)', caseSensitive: false),
    RegExp(r'([\d,]+\.?\d*)\s*(?:USD|\$)', caseSensitive: false),
    
    // Евро: €12.34
    RegExp(r'€\s*([\d\s]+[,.]?\d*)', caseSensitive: false),
    RegExp(r'([\d\s]+[,.]?\d*)\s*(?:EUR|€)', caseSensitive: false),
    
    // Универсальный: числа с "оплата", "списано", "paid"
    RegExp(r'(?:оплата|списано|paid|payment)\s*([\d\s]+[,.]?\d*)', caseSensitive: false),
  ];

  // Регулярные выражения для извлечения магазина
  static final List<RegExp> merchantPatterns = [
    RegExp(r'(?:в|at|@)\s+(.+?)(?:\s*$|\s+\d)', caseSensitive: false),
    RegExp(r'(?:в|at|@)\s+(.+)', caseSensitive: false),
  ];

  // Ключевые слова для определения платежных уведомлений
  static const List<String> paymentKeywords = [
    'оплата',
    'списано',
    'списание',
    'покупка',
    'платёж',
    'платеж',
    'payment',
    'paid',
    'purchase',
    'spent',
    'charged',
  ];

  Future<void> initialize({
    required Function(Expense) onExpenseDetected,
  }) async {
    _onExpenseDetected = onExpenseDetected;
    
    // Очистка старых хешей
    await _dbService.cleanupOldNotificationHashes();
    
    // На веб-платформе сервис работает в демо-режиме
    if (kIsWeb) {
      debugPrint('NotificationService: Running in demo mode (web platform)');
      return;
    }
    
    // На Android здесь была бы инициализация реального сервиса уведомлений
    debugPrint('NotificationService: Platform notifications not available in this build');
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return true;
    }
    // Открываем настройки приложения для предоставления разрешений
    try {
      // Используем intent для открытия настроек уведомлений
      // В реальном приложении здесь будет вызов native кода
      debugPrint('NotificationService: Opening notification settings');
      return true;
    } catch (e) {
      debugPrint('NotificationService: Failed to request permission: $e');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) {
      return true;
    }
    // На Android проверяем разрешение
    // В реальном приложении здесь будет проверка через NotificationListenerService
    return true; // Возвращаем true для демо на мобильных устройствах
  }

  /// Метод для ручного добавления расхода (имитация уведомления)
  /// Используется для тестирования и демо
  Future<void> simulateNotification({
    required double amount,
    required String merchant,
    DateTime? dateTime,
  }) async {
    final hash = _createNotificationHash(
      'manual|$amount|$merchant|${dateTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
    );
    
    final isProcessed = await _dbService.isNotificationProcessed(hash);
    if (isProcessed) return;
    
    final category = _categoryDetector.detectCategory(merchant);
    
    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      merchant: merchant,
      dateTime: dateTime ?? DateTime.now(),
      category: category,
      notificationHash: hash,
      isAutoDetected: true,
    );
    
    await _dbService.markNotificationProcessed(hash);
    _onExpenseDetected?.call(expense);
  }

  String _createNotificationHash(String content) {
    var hash = 0;
    for (var i = 0; i < content.length; i++) {
      hash = ((hash << 5) - hash) + content.codeUnitAt(i);
      hash = hash & hash;
    }
    return hash.abs().toRadixString(16);
  }

  double? extractAmount(String text) {
    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        String amountStr = match.group(1)!;
        
        // Убираем пробелы
        amountStr = amountStr.replaceAll(' ', '');
        
        // Заменяем запятую на точку для парсинга
        amountStr = amountStr.replaceAll(',', '.');
        
        // Если есть несколько точек, оставляем только последнюю
        final parts = amountStr.split('.');
        if (parts.length > 2) {
          amountStr = parts.sublist(0, parts.length - 1).join('') + '.' + parts.last;
        }
        
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    return null;
  }

  String? extractMerchant(String text) {
    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final merchant = match.group(1)!.trim();
        if (merchant.isNotEmpty && merchant.length > 1) {
          return _cleanMerchantName(merchant);
        }
      }
    }
    return null;
  }

  String _cleanMerchantName(String name) {
    // Убираем лишние символы
    var cleaned = name
        .replaceAll(RegExp(r'[^\w\s\-а-яА-ЯёЁ]'), '')
        .trim();
    
    // Ограничиваем длину
    if (cleaned.length > 50) {
      cleaned = cleaned.substring(0, 50);
    }
    
    // Делаем первую букву заглавной
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned.isEmpty ? 'Покупка' : cleaned;
  }

  void dispose() {
    // Cleanup
  }
}
