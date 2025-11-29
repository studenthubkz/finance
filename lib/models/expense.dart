import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  entertainment,
  bills,
  health,
  education,
  travel,
  transfer,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get name {
    switch (this) {
      case ExpenseCategory.food:
        return 'Еда';
      case ExpenseCategory.transport:
        return 'Транспорт';
      case ExpenseCategory.shopping:
        return 'Покупки';
      case ExpenseCategory.entertainment:
        return 'Развлечения';
      case ExpenseCategory.bills:
        return 'Счета';
      case ExpenseCategory.health:
        return 'Здоровье';
      case ExpenseCategory.education:
        return 'Образование';
      case ExpenseCategory.travel:
        return 'Путешествия';
      case ExpenseCategory.transfer:
        return 'Переводы';
      case ExpenseCategory.other:
        return 'Другое';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.health:
        return Icons.favorite_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.travel:
        return Icons.flight_rounded;
      case ExpenseCategory.transfer:
        return Icons.swap_horiz_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFEF4444);
      case ExpenseCategory.transport:
        return const Color(0xFF3B82F6);
      case ExpenseCategory.shopping:
        return const Color(0xFFEC4899);
      case ExpenseCategory.entertainment:
        return const Color(0xFF8B5CF6);
      case ExpenseCategory.bills:
        return const Color(0xFFF59E0B);
      case ExpenseCategory.health:
        return const Color(0xFF22C55E);
      case ExpenseCategory.education:
        return const Color(0xFF14B8A6);
      case ExpenseCategory.travel:
        return const Color(0xFF22D3EE);
      case ExpenseCategory.transfer:
        return const Color(0xFF6366F1);
      case ExpenseCategory.other:
        return const Color(0xFF64748B);
    }
  }
}

class Expense {
  final String id;
  final double amount;
  final String merchant;
  final DateTime dateTime;
  final ExpenseCategory category;
  final String? description;
  final String? notificationHash; // Для предотвращения дубликатов
  final bool isAutoDetected;

  Expense({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.dateTime,
    this.category = ExpenseCategory.other,
    this.description,
    this.notificationHash,
    this.isAutoDetected = true,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: map['amount'] as double,
      merchant: map['merchant'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime'] as int),
      category: ExpenseCategory.values[map['category'] as int],
      description: map['description'] as String?,
      notificationHash: map['notificationHash'] as String?,
      isAutoDetected: map['isAutoDetected'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'category': category.index,
      'description': description,
      'notificationHash': notificationHash,
      'isAutoDetected': isAutoDetected ? 1 : 0,
    };
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? merchant,
    DateTime? dateTime,
    ExpenseCategory? category,
    String? description,
    String? notificationHash,
    bool? isAutoDetected,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
      description: description ?? this.description,
      notificationHash: notificationHash ?? this.notificationHash,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
