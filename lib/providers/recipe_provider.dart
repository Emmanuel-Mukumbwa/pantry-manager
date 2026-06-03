import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';

class RecipeProvider extends ChangeNotifier {
  RecipeProvider() {
    loadRecipes();
  }

  static const String _storageKey = 'recipes_v1';

  final List<Recipe> _recipes = <Recipe>[];

  List<Recipe> get recipes => List.unmodifiable(_recipes);

  Recipe? getRecipeById(String id) {
    try {
      return _recipes.where((r) => r.id == id).first;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      _recipes.clear();
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Expected list');

      _recipes
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(Recipe.fromJson)
              .toList(),
        );
    } catch (_) {
      _recipes.clear();
    }

    notifyListeners();
  }

  Future<void> saveRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_recipes.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> addRecipe({
    required String name,
    required String description,
    required int servings,
    required List<RecipeIngredient> ingredients,
    required String instructions,
    required String category,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
  }) async {
    final id = const Uuid().v4();
    final recipe = Recipe(
      id: id,
      name: name,
      description: description,
      servings: servings,
      ingredients: ingredients,
      instructions: instructions,
      category: category,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
      createdAt: DateTime.now(),
    );

    _recipes.insert(0, recipe);
    notifyListeners();
    await saveRecipes();
  }

  Future<void> updateRecipe({
    required String id,
    required String name,
    required String description,
    required int servings,
    required List<RecipeIngredient> ingredients,
    required String instructions,
    required String category,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
  }) async {
    final index = _recipes.indexWhere((r) => r.id == id);
    if (index == -1) return;

    _recipes[index] = _recipes[index].copyWith(
      name: name,
      description: description,
      servings: servings,
      ingredients: ingredients,
      instructions: instructions,
      category: category,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
    );

    notifyListeners();
    await saveRecipes();
  }

  Future<void> deleteRecipe(String id) async {
    _recipes.removeWhere((r) => r.id == id);
    notifyListeners();
    await saveRecipes();
  }

  /// Flexible ingredient matching.
  ///
  /// Goal: avoid strict equality; allow partial match and plural/singular tolerance.
  String normalizeIngredientName(String input) {
    final s = input.trim().toLowerCase();

    // Very small plural/singular tolerance (enough for pantry stock checks).
    if (s.endsWith('es') && s.length > 3) {
      return s.substring(0, s.length - 2);
    }
    if (s.endsWith('s') && !s.endsWith('ss') && s.length > 2) {
      return s.substring(0, s.length - 1);
    }

    return s;
  }

  /// Returns a score (0..1). Higher is better.
  double ingredientMatchScore(String recipeName, String pantryName) {
    final a = normalizeIngredientName(recipeName);
    final b = normalizeIngredientName(pantryName);

    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1.0;

    // Token containment / partial match.
    if (b.contains(a) || a.contains(b)) {
      // e.g. rice <-> basmati rice
      return 0.75;
    }

    // Token overlap.
    final aTokens = a.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final bTokens = b.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;

    int overlap = 0;
    for (final t in aTokens) {
      if (bTokens.contains(t)) overlap++;
    }

    final denom = aTokens.length > bTokens.length
        ? aTokens.length
        : bTokens.length;
    return denom == 0 ? 0 : (overlap / denom).clamp(0.0, 0.6);
  }

  PantryItem? findBestMatchingPantryItem({
    required String ingredientName,
    required List<PantryItem> pantryItems,
    double minScore = 0.45,
  }) {
    PantryItem? best;
    double bestScore = 0;

    for (final p in pantryItems) {
      final score = ingredientMatchScore(ingredientName, p.name);
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }

    if (bestScore < minScore) return null;
    return best;
  }

  /// Checks if pantry has enough stock for the given recipe.
  ///
  /// Returns missing or short items as strings (for UX).
  List<String> validateRecipeAgainstPantry({
    required Recipe recipe,
    required List<PantryItem> pantry,
  }) {
    final missing = <String>[];

    for (final ing in recipe.ingredients) {
      final match = findBestMatchingPantryItem(
        ingredientName: ing.name,
        pantryItems: pantry,
      );

      if (match == null) {
        missing.add('${ing.name} (missing)');
        continue;
      }

      // Simple quantity check (unit is not normalized here; current model uses free-form unit)
      // Pantry subtraction uses pantry units as stored.
      if (match.quantity + 1e-9 < ing.quantity) {
        missing.add(
          '${ing.name} (short: need ${ing.quantity.toStringAsFixed(2)}, have ${match.quantity.toStringAsFixed(2)} ${match.unit})',
        );
      }
    }

    return missing;
  }

  /// Builds a deduction plan: which pantry item to deduct and how much.
  ///
  /// This uses flexible ingredient matching.
  ///
  /// If not found or short, it will omit those entries.
  List<_Deduction> buildDeductionPlanForRecipe({
    required Recipe recipe,
    required List<PantryItem> pantry,
  }) {
    final result = <_Deduction>[];

    for (final ing in recipe.ingredients) {
      final match = findBestMatchingPantryItem(
        ingredientName: ing.name,
        pantryItems: pantry,
      );
      if (match == null) continue;

      if (match.quantity + 1e-9 < ing.quantity) continue;

      result.add(_Deduction(pantryItemId: match.id, amount: ing.quantity));
    }

    return result;
  }
}

class _Deduction {
  _Deduction({required this.pantryItemId, required this.amount});

  final String pantryItemId;
  final double amount;
}

extension _RecipeCopyWith on Recipe {
  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    int? servings,
    List<RecipeIngredient>? ingredients,
    String? instructions,
    String? category,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      category: category ?? this.category,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
