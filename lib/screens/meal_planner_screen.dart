import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/meal_planner_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/pantry_provider.dart';
import '../models/meal_plan_entry.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  late DateTime _startOfWeek;

  @override
  void initState() {
    super.initState();
    _startOfWeek = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(const Duration(days: 7));
    });
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
        title: const Text('Meal Planner', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(onPressed: _previousWeek, icon: const Icon(Icons.arrow_back, color: Colors.black87)),
          Text(
            DateFormat('MMM d').format(_startOfWeek),
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(width: 8),
          const Text('-', style: TextStyle(color: Colors.black87)),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM d').format(_startOfWeek.add(const Duration(days: 6))),
            style: const TextStyle(color: Colors.black87),
          ),
          IconButton(onPressed: _nextWeek, icon: const Icon(Icons.arrow_forward, color: Colors.black87)),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = weekDays[index];
          final isPast = date.isBefore(DateTime.now());
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.black12),
              child: ExpansionTile(
                title: Text(
                  '${DateFormat('EEEE').format(date)} (${DateFormat('MMM d').format(date)})',
                  style: TextStyle(
                    color: isPast ? Colors.black54 : Colors.black87,
                    decoration: isPast ? TextDecoration.lineThrough : null,
                  ),
                ),
                children: [
                  _MealSlot(
                    mealType: 'Breakfast',
                    date: date,
                    existingMeal: _findMeal(meals, date, MealType.breakfast),
                    isPast: isPast,
                  ),
                  const Divider(),
                  _MealSlot(
                    mealType: 'Lunch',
                    date: date,
                    existingMeal: _findMeal(meals, date, MealType.lunch),
                    isPast: isPast,
                  ),
                  const Divider(),
                  _MealSlot(
                    mealType: 'Dinner',
                    date: date,
                    existingMeal: _findMeal(meals, date, MealType.dinner),
                    isPast: isPast,
                  ),
                ],
              ),
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
    required this.isPast,
  });

  final String mealType;
  final DateTime date;
  final MealPlanEntry? existingMeal;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final mealPlanner = Provider.of<MealPlannerProvider>(context, listen: false);
    final pantryProvider = Provider.of<PantryProvider>(context, listen: false);

    return ListTile(
      leading: Icon(
        mealType == 'Breakfast'
            ? Icons.free_breakfast
            : mealType == 'Lunch'
            ? Icons.lunch_dining
            : Icons.dinner_dining,
        color: Colors.black54,
      ),
      title: Text(
        mealType,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      ),
      subtitle: existingMeal != null
          ? Text(
              recipeProvider.getRecipeById(existingMeal!.recipeId)?.name ?? 'Unknown',
              style: const TextStyle(color: Colors.black54),
            )
          : const Text('Not planned', style: TextStyle(color: Colors.black54)),
      trailing: isPast
          ? const Icon(Icons.lock, color: Colors.black38)
          : IconButton(
              icon: const Icon(Icons.edit, color: Colors.black54),
              onPressed: () async {
                final recipes = recipeProvider.recipes;
                if (recipes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No recipes. Create one first.')),
                  );
                  return;
                }
                final selected = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (ctx) {
                    String? selectedId;
                    return AlertDialog(
                      title: const Text('Select Recipe'),
                      content: DropdownButton<String>(
                        hint: const Text('Choose recipe'),
                        value: selectedId,
                        items: recipes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                        onChanged: (v) => selectedId = v,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () {
                            if (selectedId != null) Navigator.pop(ctx, {'recipeId': selectedId});
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
                if (selected != null && selected['recipeId'] != null) {
                  final mealTypeEnum = mealType.toLowerCase();
                  final success = await mealPlanner.addMealPlanEntryWithValidation(
                    date: date,
                    mealType: mealTypeEnum == 'breakfast'
                        ? MealType.breakfast
                        : mealTypeEnum == 'lunch'
                        ? MealType.lunch
                        : MealType.dinner,
                    recipeId: selected['recipeId'],
                    pantryProvider: pantryProvider,
                    recipeProvider: recipeProvider,
                  );
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Not enough ingredients in pantry.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
      onTap: (existingMeal != null && !isPast)
          ? () async {
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
              if (confirm == true) {
                final success = await mealPlanner.markMealAsCookedWithDeduction(
                  mealPlanId: existingMeal!.id,
                  pantryProvider: pantryProvider,
                  recipeProvider: recipeProvider,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Meal cooked! Stock updated.' : 'Could not deduct ingredients.'),
                      backgroundColor: success ? Colors.green : Colors.orange,
                    ),
                  );
                }
              }
            }
          : null,
    );
  }
}