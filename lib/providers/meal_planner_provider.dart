import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/meal_plan_entry.dart';
import 'pantry_provider.dart';
import 'recipe_provider.dart';

class MealPlannerProvider extends ChangeNotifier {
  MealPlannerProvider() {
    loadMealPlan();
  }

  static const String _storageKey = 'meal_plan_v1';

  final List<MealPlanEntry> _mealPlan = <MealPlanEntry>[];

  List<MealPlanEntry> get mealPlan => List.unmodifiable(_mealPlan);

  MealPlanEntry? getMealPlanById(String id) {
    try {
      return _mealPlan.where((m) => m.id == id).first;
    } catch (_) {
      return null;
    }
  }

  List<MealPlanEntry> getMealsForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _mealPlan
        .where(
          (m) => DateTime(m.date.year, m.date.month, m.date.day) == normalized,
        )
        .toList(growable: false);
  }

  List<MealPlanEntry> getCurrentWeekMeals() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _mealPlan
        .where(
          (m) =>
              m.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              m.date.isBefore(endOfWeek.add(const Duration(days: 1))),
        )
        .toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<MealPlanEntry> getPlannedMeals() {
    final now = DateTime.now();
    return _mealPlan
        .where(
          (m) =>
              m.date.isAfter(now.subtract(const Duration(days: 1))) &&
              m.status == MealStatus.planned,
        )
        .toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> loadMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _mealPlan.clear();
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Expected list');
      _mealPlan
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(MealPlanEntry.fromJson)
              .toList(),
        );
    } catch (_) {
      _mealPlan.clear();
    }
    notifyListeners();
  }

  Future<void> saveMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_mealPlan.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  /// Validates if a recipe can be scheduled given current pantry stock.
  Future<({bool canSchedule, List<String> errors})> canScheduleMeal({
    required String recipeId,
    required PantryProvider pantryProvider,
    required RecipeProvider recipeProvider,
  }) async {
    final recipe = recipeProvider.getRecipeById(recipeId);
    if (recipe == null) {
      return (canSchedule: false, errors: ['Recipe not found']);
    }
    final missing = recipeProvider.validateRecipeAgainstPantry(
      recipe: recipe,
      pantry: pantryProvider.items,
    );
    return (canSchedule: missing.isEmpty, errors: missing);
  }

  /// Adds a meal plan entry only if stock is sufficient.
  Future<bool> addMealPlanEntryWithValidation({
    required DateTime date,
    required MealType mealType,
    required String recipeId,
    required PantryProvider pantryProvider,
    required RecipeProvider recipeProvider,
    String? notes,
  }) async {
    final validation = await canScheduleMeal(
      recipeId: recipeId,
      pantryProvider: pantryProvider,
      recipeProvider: recipeProvider,
    );
    if (!validation.canSchedule) {
      return false;
    }
    final id = const Uuid().v4();
    final entry = MealPlanEntry(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      mealType: mealType,
      recipeId: recipeId,
      status: MealStatus.planned,
      notes: notes,
    );
    _mealPlan.insert(0, entry);
    notifyListeners();
    await saveMealPlan();
    return true;
  }

  Future<void> updateMealPlanEntry({
    required String id,
    required DateTime date,
    required MealType mealType,
    required String recipeId,
    required MealStatus status,
    String? notes,
  }) async {
    final index = _mealPlan.indexWhere((m) => m.id == id);
    if (index == -1) return;
    _mealPlan[index] = MealPlanEntry(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      mealType: mealType,
      recipeId: recipeId,
      status: status,
      notes: notes,
    );
    notifyListeners();
    await saveMealPlan();
  }

  /// Marks a meal as cooked and deducts all ingredients from pantry.
  Future<bool> markMealAsCookedWithDeduction({
    required String mealPlanId,
    required PantryProvider pantryProvider,
    required RecipeProvider recipeProvider,
  }) async {
    final entry = getMealPlanById(mealPlanId);
    if (entry == null) return false;
    final recipe = recipeProvider.getRecipeById(entry.recipeId);
    if (recipe == null) return false;

    final deductions = recipeProvider.buildDeductionPlanForRecipe(
      recipe: recipe,
      pantry: pantryProvider.items,
    );
    if (deductions.isEmpty) return false;

    final success = await pantryProvider.deductMultipleItems(
      deductions: deductions
          .map((d) => (id: d.pantryItemId, amount: d.amount))
          .toList(),
      source: 'meal_${entry.mealType.name}_${entry.date.toIso8601String()}',
      recipeId: recipe.id,
    );
    if (!success) return false;

    final index = _mealPlan.indexWhere((m) => m.id == mealPlanId);
    if (index != -1) {
      _mealPlan[index] = MealPlanEntry(
        id: entry.id,
        date: entry.date,
        mealType: entry.mealType,
        recipeId: entry.recipeId,
        status: MealStatus.cooked,
        notes: entry.notes,
      );
      notifyListeners();
      await saveMealPlan();
    }
    return true;
  }

  Future<void> markMealAsSkipped(String id) async {
    final index = _mealPlan.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final entry = _mealPlan[index];
    _mealPlan[index] = MealPlanEntry(
      id: entry.id,
      date: entry.date,
      mealType: entry.mealType,
      recipeId: entry.recipeId,
      status: MealStatus.skipped,
      notes: entry.notes,
    );
    notifyListeners();
    await saveMealPlan();
  }

  Future<void> deleteMealPlanEntry(String id) async {
    _mealPlan.removeWhere((m) => m.id == id);
    notifyListeners();
    await saveMealPlan();
  }
}