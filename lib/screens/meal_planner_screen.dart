import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/meal_planner_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/pantry_provider.dart';
import '../models/meal_plan_entry.dart';
import '../widgets/recipe_search_bottom_sheet.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  late DateTime _startOfWeek;

  final Map<String, TimeOfDay> _mealLockTimes = {
    'Breakfast': const TimeOfDay(hour: 9, minute: 30),
    'Lunch': const TimeOfDay(hour: 13, minute: 30),
    'Dinner': const TimeOfDay(hour: 21, minute: 30),
  };

  @override
  void initState() {
    super.initState();
    _startOfWeek = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));

  void _previousWeek() => setState(() => _startOfWeek = _startOfWeek.subtract(const Duration(days: 7)));
  void _nextWeek() => setState(() => _startOfWeek = _startOfWeek.add(const Duration(days: 7)));

  /// Returns true if the given date is before today (ignoring time).
  bool _isPastDay(DateTime date) {
    final today = DateTime.now();
    return date.year < today.year || (date.year == today.year && date.month < today.month) ||
        (date.year == today.year && date.month == today.month && date.day < today.day);
  }

  /// Returns true if the meal slot for a given date and meal type is locked due to time passing.
  bool _isSlotLocked(DateTime date, String mealType) {
    final now = DateTime.now();
    // Future days are never locked
    if (date.isAfter(now)) return false;
    // Past days (full day before today) are fully locked
    if (_isPastDay(date)) return true;
    // Today: check against lock time
    final lockTime = _mealLockTimes[mealType];
    if (lockTime == null) return false;
    final lockDateTime = DateTime(now.year, now.month, now.day, lockTime.hour, lockTime.minute);
    return now.isAfter(lockDateTime);
  }

  Future<void> _selectRecipeForSlot(DateTime date, String mealType, MealPlanEntry? existingEntry, List<MealPlanEntry> existingMeals) async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final allRecipes = recipeProvider.recipes;
    if (allRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No recipes yet. Create one first.')));
      return;
    }

    // Exclude recipes already planned for the same slot on the same day
    final excludeIds = <String>[];
    for (final m in existingMeals) {
      if (m.date.year == date.year && m.date.month == date.month && m.date.day == date.day && m.mealType.name.toLowerCase() == mealType.toLowerCase()) {
        if (m.recipeId.isNotEmpty) excludeIds.add(m.recipeId);
      }
    }

    final selectedRecipe = await showRecipeSearchBottomSheet(context, allRecipes, excludeRecipeIds: excludeIds);
    if (selectedRecipe == null) return;

    final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
    final missing = recipeProvider.validateRecipeAgainstPantry(recipe: selectedRecipe, pantry: pantryProvider.items);
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot plan: ${missing.take(2).join(', ')}'), backgroundColor: Colors.orange),
      );
      return;
    }

    final mealPlanner = Provider.of<MealPlannerProvider>(context, listen: false);
    final mealTypeEnum = _mealTypeFromString(mealType);
    if (existingEntry == null) {
      final success = await mealPlanner.addMealPlanEntryWithValidation(
        date: date,
        mealType: mealTypeEnum,
        recipeId: selectedRecipe.id,
        pantryProvider: pantryProvider,
        recipeProvider: recipeProvider,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough ingredients in pantry.'), backgroundColor: Colors.red));
      }
    } else {
      if (_isSlotLocked(date, mealType)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This meal slot is locked (time has passed).')));
        return;
      }
      await mealPlanner.updateMealPlanEntry(
        id: existingEntry.id,
        date: date,
        mealType: mealTypeEnum,
        recipeId: selectedRecipe.id,
        status: existingEntry.status,
        notes: existingEntry.notes,
      );
    }
    setState(() {});
  }

  MealType _mealTypeFromString(String s) {
    switch (s.toLowerCase()) {
      case 'breakfast': return MealType.breakfast;
      case 'lunch': return MealType.lunch;
      default: return MealType.dinner;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealPlanner = context.watch<MealPlannerProvider>();
    final recipeProvider = context.watch<RecipeProvider>();
    final pantryProvider = context.watch<PantryProvider>();

    final weekDays = List.generate(7, (i) => _startOfWeek.add(Duration(days: i)));
    final meals = mealPlanner.getCurrentWeekMeals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(onPressed: _previousWeek, icon: const Icon(Icons.arrow_back)),
          Text(DateFormat('MMM d').format(_startOfWeek)),
          const SizedBox(width: 8),
          const Text('-'),
          const SizedBox(width: 8),
          Text(DateFormat('MMM d').format(_startOfWeek.add(const Duration(days: 6)))),
          IconButton(onPressed: _nextWeek, icon: const Icon(Icons.arrow_forward)),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = weekDays[index];
          final isPastDay = _isPastDay(date);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                '${DateFormat('EEEE').format(date)} (${DateFormat('MMM d').format(date)})',
                style: TextStyle(
                  color: isPastDay ? Colors.grey : Colors.black87,
                  decoration: isPastDay ? TextDecoration.lineThrough : null,
                ),
              ),
              children: [
                _MealSlot(
                  mealType: 'Breakfast',
                  date: date,
                  existingMeal: _findMeal(meals, date, MealType.breakfast),
                  isLocked: _isSlotLocked(date, 'Breakfast'),
                  onSelect: () => _selectRecipeForSlot(date, 'Breakfast', _findMeal(meals, date, MealType.breakfast), meals),
                ),
                const Divider(),
                _MealSlot(
                  mealType: 'Lunch',
                  date: date,
                  existingMeal: _findMeal(meals, date, MealType.lunch),
                  isLocked: _isSlotLocked(date, 'Lunch'),
                  onSelect: () => _selectRecipeForSlot(date, 'Lunch', _findMeal(meals, date, MealType.lunch), meals),
                ),
                const Divider(),
                _MealSlot(
                  mealType: 'Dinner',
                  date: date,
                  existingMeal: _findMeal(meals, date, MealType.dinner),
                  isLocked: _isSlotLocked(date, 'Dinner'),
                  onSelect: () => _selectRecipeForSlot(date, 'Dinner', _findMeal(meals, date, MealType.dinner), meals),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  MealPlanEntry? _findMeal(List<MealPlanEntry> meals, DateTime date, MealType type) {
    try {
      return meals.firstWhere(
        (m) => m.date.year == date.year && m.date.month == date.month && m.date.day == date.day && m.mealType == type,
      );
    } catch (_) {
      return null;
    }
  }
}

class _MealSlot extends StatelessWidget {
  const _MealSlot({
    required this.mealType,
    required this.date,
    this.existingMeal,
    required this.isLocked,
    required this.onSelect,
  });

  final String mealType;
  final DateTime date;
  final MealPlanEntry? existingMeal;
  final bool isLocked;
  final VoidCallback onSelect;

  Future<void> _markAsCooked(BuildContext context, MealPlanEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as cooked?'),
        content: const Text('This will deduct all ingredients from your pantry.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cook')),
        ],
      ),
    );
    if (confirm != true) return;
    final mealPlanner = Provider.of<MealPlannerProvider>(context, listen: false);
    final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final success = await mealPlanner.markMealAsCookedWithDeduction(
      mealPlanId: entry.id,
      pantryProvider: pantryProvider,
      recipeProvider: recipeProvider,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Meal cooked! Stock updated.' : 'Could not deduct ingredients.'), backgroundColor: success ? Colors.green : Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final recipeName = existingMeal != null ? recipeProvider.getRecipeById(existingMeal!.recipeId)?.name ?? 'Unknown' : null;

    return ListTile(
      leading: Icon(
        mealType == 'Breakfast' ? Icons.free_breakfast : mealType == 'Lunch' ? Icons.lunch_dining : Icons.dinner_dining,
        color: Colors.black54,
      ),
      title: Text(mealType, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
      subtitle: Text(recipeName ?? 'Not planned', style: const TextStyle(color: Colors.black54)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (existingMeal != null && existingMeal!.status == MealStatus.planned && !isLocked)
            IconButton(
              icon: const Icon(Icons.kitchen, color: Colors.green),
              onPressed: () => _markAsCooked(context, existingMeal!),
              tooltip: 'Mark as cooked',
            ),
          if (!isLocked)
            IconButton(
              icon: Icon(existingMeal == null ? Icons.add : Icons.edit, color: Colors.teal),
              onPressed: onSelect,
              tooltip: existingMeal == null ? 'Plan a meal' : 'Edit meal',
            ),
        ],
      ),
    );
  }
}