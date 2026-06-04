import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider() {
    _load();
  }

  static const String _storageKey = 'expense_data_v1';

  List<Map<String, dynamic>> _purchases = []; // {date, amount, category}
  double _totalSpent = 0.0;

  double get totalSpent => _totalSpent;

  List<Map<String, dynamic>> get purchases => List.unmodifiable(_purchases);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw);
        _purchases = List<Map<String, dynamic>>.from(data['purchases'] ?? []);
        _totalSpent = (data['totalSpent'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        _purchases = [];
        _totalSpent = 0.0;
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'purchases': _purchases,
      'totalSpent': _totalSpent,
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// Record a new purchase (when an item is added with a total cost)
  Future<void> recordPurchase(DateTime date, double amount, String category) async {
    if (amount <= 0) return;
    _purchases.add({
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category,
    });
    _totalSpent += amount;
    notifyListeners();
    await _save();
  }

  /// Record an adjustment (positive or negative) due to editing an item’s price/quantity
  Future<void> recordAdjustment(DateTime date, double amount, String category) async {
    if (amount == 0) return;
    _purchases.add({
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category,
      'note': 'adjustment',
    });
    _totalSpent += amount;
    notifyListeners();
    await _save();
  }

  /// Total spent per month (purchases only)
  Map<String, double> get monthlyPurchases {
    final map = <String, double>{};
    for (final p in _purchases) {
      final dt = DateTime.parse(p['date'] as String);
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + (p['amount'] as num).toDouble();
    }
    return map;
  }

  /// Total spent per category (purchases only)
  Map<String, double> get categoryPurchases {
    final map = <String, double>{};
    for (final p in _purchases) {
      final cat = p['category'] as String? ?? 'Uncategorized';
      map[cat] = (map[cat] ?? 0) + (p['amount'] as num).toDouble();
    }
    return map;
  }

  /// Helper to clear all data (if ever needed)
  Future<void> clearAll() async {
    _purchases.clear();
    _totalSpent = 0.0;
    notifyListeners();
    await _save();
  }
}