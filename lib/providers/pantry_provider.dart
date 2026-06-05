import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/consumption_record.dart';
import '../models/pantry_item.dart';

class PantryProvider extends ChangeNotifier {
  PantryProvider() {
    loadItems();
    loadCustomUnits();
    loadCustomCategories();
  }

  static const String _storageKey = 'pantry_items_v1';
  static const String _customUnitsKey = 'custom_units_v1';
  static const String _customCategoriesKey = 'custom_categories_v1';
  static const String defaultCategory = 'Grains';
  static const String defaultUnit = 'pieces';

  final List<PantryItem> _items = <PantryItem>[];
  List<String> _customUnits = [];
  List<String> _customCategories = [];

  List<PantryItem> get items => List.unmodifiable(_items);
  List<String> get customUnits => List.unmodifiable(_customUnits);
  List<String> get customCategories => List.unmodifiable(_customCategories);

  /// Total monetary value of all items in inventory
  double get totalInventoryValue {
    double sum = 0.0;
    for (final item in _items) {
      sum += item.totalValue;
    }
    return sum;
  }

  // --- Custom units management ---
  Future<void> loadCustomUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_customUnitsKey);
    _customUnits = raw != null ? raw.toList() : [];
    notifyListeners();
  }

  Future<void> saveCustomUnits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customUnitsKey, _customUnits);
  }

  Future<void> addCustomUnit(String unit) async {
    final normalized = unit.trim().toLowerCase();
    if (normalized.isEmpty) return;
    if (!_customUnits.contains(normalized)) {
      _customUnits.add(normalized);
      await saveCustomUnits();
      notifyListeners();
    }
  }

  // --- Custom categories management ---
  Future<void> loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_customCategoriesKey);
    _customCategories = raw != null ? raw.toList() : [];
    notifyListeners();
  }

  Future<void> saveCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customCategoriesKey, _customCategories);
  }

  Future<void> addCustomCategory(String category) async {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty) return;
    if (!_customCategories.contains(normalized)) {
      _customCategories.add(normalized);
      await saveCustomCategories();
      notifyListeners();
    }
  }

  // --- Existing getters ---
  List<PantryItem> get lowStockItems =>
      _items.where((e) => e.quantity <= e.threshold).toList(growable: false);

  List<PantryItem> getItemsExpiringWithin(int days) {
    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    return _items
        .where(
          (e) =>
              e.expiryDate.isAfter(now.subtract(const Duration(days: 1))) &&
              e.expiryDate.isBefore(end.add(const Duration(days: 1))),
        )
        .toList(growable: false)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  List<PantryItem> get expiredItems {
    final now = DateTime.now();
    return _items
        .where((e) => e.expiryDate.isBefore(now))
        .toList(growable: false)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  List<ConsumptionRecord> get recentConsumption {
    final all = <ConsumptionRecord>[];
    for (final p in _items) {
      all.addAll(p.consumptionHistory);
    }
    all.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return all.take(10).toList(growable: false);
  }

  List<PantryItem> get recentlyAdded {
    final sorted = List<PantryItem>.from(_items)
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return sorted.take(10).toList(growable: false);
  }

  String get mostStockedCategory {
    if (_items.isEmpty) return 'None';
    final catMap = <String, double>{};
    for (final item in _items) {
      catMap[item.category] = (catMap[item.category] ?? 0) + item.quantity;
    }
    return catMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get mostUsedCategory {
    final catUsage = <String, double>{};
    for (final item in _items) {
      double totalConsumed = 0;
      for (final record in item.consumptionHistory) {
        totalConsumed += record.amount;
      }
      if (totalConsumed > 0) {
        catUsage[item.category] = (catUsage[item.category] ?? 0) + totalConsumed;
      }
    }
    if (catUsage.isEmpty) return 'None';
    return catUsage.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<String, double> getCategoryDistribution() {
    final map = <String, double>{};
    for (final item in _items) {
      map[item.category] = (map[item.category] ?? 0) + item.quantity;
    }
    return map;
  }

  Map<DateTime, double> getWeeklyConsumption(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final result = <DateTime, double>{};
    for (final item in _items) {
      for (final record in item.consumptionHistory) {
        if (record.dateTime.isAfter(startOfWeek) &&
            record.dateTime.isBefore(endOfWeek)) {
          final day = DateTime(record.dateTime.year, record.dateTime.month,
              record.dateTime.day);
          result[day] = (result[day] ?? 0) + record.amount;
        }
      }
    }
    return result;
  }

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _items.clear();
      notifyListeners();
      return;
    }
    try {
      final decoded = PantryItem.decodeItems(raw);
      _items..clear()..addAll(decoded);
    } catch (_) {
      _items.clear();
    }
    notifyListeners();
  }

  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, PantryItem.encodeItems(_items));
  }

  // --- NEW: Clear all data for reset ---
  Future<void> clearAll() async {
    _items.clear();
    _customUnits.clear();
    _customCategories.clear();
    notifyListeners();
    await saveItems();
    await saveCustomUnits();
    await saveCustomCategories();
  }

  /// Find an existing pantry item that is a duplicate of the given name/unit.
  PantryItem? findDuplicateItem({
    required String name,
    required String unit,
  }) {
    for (final item in _items) {
      if (item.unit != unit) continue;
      if (namesMatch(query: name, candidate: item.name)) {
        return item;
      }
    }
    return null;
  }

  /// Merge a new item's data into an existing item.
  Future<void> mergeWithExistingItem({
    required String existingId,
    required double addedQuantity,
    required DateTime newExpiryDate,
    required double newThreshold,
    double? newPricePerUnit,
  }) async {
    final index = _items.indexWhere((e) => e.id == existingId);
    if (index == -1) return;
    final existing = _items[index];

    final mergedQuantity = existing.quantity + max(0.0, addedQuantity);

    double? mergedPrice;
    if (existing.pricePerUnit != null && newPricePerUnit != null) {
      mergedPrice = mergedQuantity > 0
          ? ((existing.pricePerUnit! * existing.quantity) +
                  (newPricePerUnit * addedQuantity)) /
              mergedQuantity
          : newPricePerUnit;
    } else {
      mergedPrice = newPricePerUnit ?? existing.pricePerUnit;
    }

    final mergedExpiry = newExpiryDate.isAfter(existing.expiryDate)
        ? newExpiryDate
        : existing.expiryDate;

    final mergedThreshold =
        newThreshold > existing.threshold ? newThreshold : existing.threshold;

    _items[index] = existing.copyWith(
      quantity: mergedQuantity,
      expiryDate: mergedExpiry,
      threshold: mergedThreshold,
      pricePerUnit: mergedPrice,
    );
    notifyListeners();
    await saveItems();
  }

  Future<void> addItem({
    required String name,
    required double quantity,
    required String category,
    required DateTime expiryDate,
    required String unit,
    required double threshold,
    double? pricePerUnit,
  }) async {
    final id = const Uuid().v4();
    final item = PantryItem(
      id: id,
      name: name,
      quantity: max(0.0, quantity),
      category: category,
      expiryDate: expiryDate,
      unit: unit,
      threshold: threshold,
      addedDate: DateTime.now(),
      consumptionHistory: const <ConsumptionRecord>[],
      pricePerUnit: pricePerUnit,
    );
    _items.insert(0, item);
    notifyListeners();
    await saveItems();
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required double quantity,
    required String category,
    required DateTime expiryDate,
    required String unit,
    required double threshold,
    double? pricePerUnit,
  }) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(
      name: name,
      quantity: max(0.0, quantity),
      category: category,
      expiryDate: expiryDate,
      unit: unit,
      threshold: threshold,
      pricePerUnit: pricePerUnit,
    );
    notifyListeners();
    await saveItems();
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await saveItems();
  }

  // --- Matching logic ---
  String normalizeName(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\.\,\(\)\[\]\{\}]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    if (s.endsWith('s') && s.length > 3) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  bool namesMatch({required String query, required String candidate}) {
    final q = normalizeName(query);
    final c = normalizeName(candidate);
    if (q.isEmpty || c.isEmpty) return false;
    if (q == c) return true;
    if (c.contains(q) || q.contains(c)) return true;
    final qTokens = q.split(' ').where((t) => t.length >= 3).toList();
    final cTokens = c.split(' ').where((t) => t.length >= 3).toList();
    for (final qt in qTokens) {
      if (cTokens.any((ct) => ct.startsWith(qt) || qt.startsWith(ct))) {
        return true;
      }
    }
    return false;
  }

  PantryItem? findMatchingPantryItem({
    required String ingredientName,
    String? unit,
  }) {
    final candidates = _items.where((p) {
      final unitOk = unit == null ? true : p.unit == unit;
      return unitOk && namesMatch(query: ingredientName, candidate: p.name);
    });
    final sorted = candidates.toList()
      ..sort((a, b) {
        final aNorm = normalizeName(a.name);
        final bNorm = normalizeName(b.name);
        final qNorm = normalizeName(ingredientName);
        int score(String norm) {
          if (norm == qNorm) return 3;
          if (norm.contains(qNorm) || qNorm.contains(norm)) return 2;
          return 1;
        }
        return score(bNorm).compareTo(score(aNorm));
      });
    return sorted.isNotEmpty ? sorted.first : null;
  }

  // --- Stock deduction ---
  Future<void> consumeItem(
    String id, {
    required double amount,
    required String source,
    String? recipeId,
  }) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final now = DateTime.now();
    final current = _items[index];
    final safeAmount = amount.clamp(0.0, current.quantity);
    final nextQty = (current.quantity - safeAmount).clamp(0.0, double.infinity);

    _items[index] = current.copyWith(
      quantity: nextQty,
      lastUsedDate: now,
      consumptionHistory: <ConsumptionRecord>[
        ...current.consumptionHistory,
        ConsumptionRecord(
          id: const Uuid().v4(),
          dateTime: now,
          amount: safeAmount,
          unit: current.unit,
          remainingQuantity: nextQty,
          source: source,
          itemId: id,
          recipeId: recipeId,
        ),
      ],
    );
    notifyListeners();
    await saveItems();
  }

  Future<void> discardItem(String id, {required String source}) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final current = _items[index];
    await consumeItem(id, amount: current.quantity, source: source);
  }

  Future<bool> deductMultipleItems({
    required List<({String id, double amount})> deductions,
    required String source,
    String? recipeId,
  }) async {
    for (final deduction in deductions) {
      final item = _items.firstWhere(
        (e) => e.id == deduction.id,
        orElse: () => throw Exception('Item not found: ${deduction.id}'),
      );
      if (item.quantity + 1e-9 < deduction.amount) return false;
    }
    for (final deduction in deductions) {
      await consumeItem(deduction.id,
          amount: deduction.amount, source: source, recipeId: recipeId);
    }
    return true;
  }
}