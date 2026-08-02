import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ExpiryStatus { rightNow, fresh, soon, expired }

class Product {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit; // adet, kg, lt vb.
  final DateTime expiryDate;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
  });

  int get daysUntilExpiry {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiryOnly.difference(todayOnly).inDays;
  }

  ExpiryStatus get status {
    final days = daysUntilExpiry;
    if (days == 0) return ExpiryStatus.rightNow;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 3) return ExpiryStatus.soon;
    return ExpiryStatus.fresh;
  }

  Color get statusColor {
    switch (status) {
      case ExpiryStatus.rightNow:
        return AppTheme.statusSoon;
      case ExpiryStatus.fresh:
        return AppTheme.statusFresh;
      case ExpiryStatus.soon:
        return AppTheme.statusSoon;
      case ExpiryStatus.expired:
        return AppTheme.statusExpired;
    }
  }

  String get statusLabel {
    switch (status) {
      case ExpiryStatus.rightNow:
        return 'SKT\'si Bugün Doluyor';
      case ExpiryStatus.fresh:
        return 'Taze';
      case ExpiryStatus.soon:
        return 'SKT Yaklaşıyor (${daysUntilExpiry}g)';
      case ExpiryStatus.expired:
        return 'SKT Geçti';
    }
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'expiryDate': expiryDate.toIso8601String(),
      };

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
        id: id,
        name: map['name'] as String,
        category: map['category'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String,
        expiryDate: DateTime.parse(map['expiryDate'] as String),
      );
}

List<Product> demoProducts() {
  final now = DateTime.now();
  return [
    Product(
      id: '1',
      name: 'Süt',
      category: 'Süt Ürünleri',
      quantity: 1,
      unit: 'lt',
      expiryDate: now.add(const Duration(days: 1)),
    ),
    Product(
      id: '2',
      name: 'Yumurta',
      category: 'Kahvaltılık',
      quantity: 10,
      unit: 'adet',
      expiryDate: now.add(const Duration(days: 10)),
    ),
    Product(
      id: '3',
      name: 'Yoğurt',
      category: 'Süt Ürünleri',
      quantity: 1,
      unit: 'kg',
      expiryDate: now.subtract(const Duration(days: 1)),
    ),
  ];
}
