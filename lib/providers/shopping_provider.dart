import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import 'pantry_provider.dart';

class ShoppingProvider extends ChangeNotifier {
  ShoppingProvider() {
    loadShoppingItems();
  }

  static const String _storageKey = 'shopping_items_v1';

  final List<ShoppingItem> _shoppingList = <ShoppingItem>[];

  List<ShoppingItem> get shoppingList => List.unmodifiable(_shoppingList);
  int get unpurchasedCount => _shoppingList.where((e) => !e.isPurchased).length;

  Future<void> loadShoppingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _shoppingList.clear();
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Expected list');
      _shoppingList
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => ShoppingItem.fromJson(e))
              .toList(),
        );
    } catch (_) {
      _shoppingList.clear();
    }
    notifyListeners();
  }

  Future<void> saveShoppingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_shoppingList.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> addToShoppingList(ShoppingItem item) async {
    _shoppingList.insert(0, item);
    notifyListeners();
    await saveShoppingItems();
  }

  Future<void> updateShoppingItem({
    required String id,
    required String name,
    required double quantity,
    required String unit,
    required bool isPurchased,
  }) async {
    final index = _shoppingList.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _shoppingList[index] = ShoppingItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      isPurchased: isPurchased,
    );
    notifyListeners();
    await saveShoppingItems();
  }

  Future<void> removeFromShoppingList(String id) async {
    _shoppingList.removeWhere((e) => e.id == id);
    notifyListeners();
    await saveShoppingItems();
  }

  Future<void> togglePurchased(String id) async {
    final index = _shoppingList.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _shoppingList[index] = _shoppingList[index].copyWith(
      isPurchased: !_shoppingList[index].isPurchased,
    );
    notifyListeners();
    await saveShoppingItems();
  }

  Future<void> moveToPantry({
    required String shoppingId,
    required PantryProvider pantryProvider,
  }) async {
    final item = _shoppingList.where((e) => e.id == shoppingId).firstOrNull;
    if (item == null) return;
    await pantryProvider.addItem(
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      threshold: 1,
      category: PantryProvider.defaultCategory,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
    );
    await removeFromShoppingList(shoppingId);
  }

  Future<void> generateShoppingListFromLowStock({
    required PantryProvider pantryProvider,
  }) async {
    for (final p in pantryProvider.lowStockItems) {
      final exists = _shoppingList.any(
        (s) =>
            s.name == p.name &&
            s.unit == p.unit &&
            !s.isPurchased,
      );
      if (exists) continue;
      await addToShoppingList(
        ShoppingItem(
          id: const Uuid().v4(),
          name: p.name,
          quantity: p.threshold.toDouble(),
          unit: p.unit,
          isPurchased: false,
        ),
      );
    }
  }
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    for (final e in this) {
      return e;
    }
    return null;
  }
}