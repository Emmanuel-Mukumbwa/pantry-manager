import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/pantry_provider.dart';
import 'add_edit_recipe_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    final recipe = recipeProvider.getRecipeById(recipeId);
    if (recipe == null) {
      return const Scaffold(
        body: Center(child: Text('Recipe not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.description.isNotEmpty)
              Text(recipe.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _InfoRow(label: 'Category', value: recipe.category),
            _InfoRow(label: 'Servings', value: recipe.servings.toString()),
            if (recipe.prepTimeMinutes != null)
              _InfoRow(
                label: 'Prep time',
                value: '${recipe.prepTimeMinutes} min',
              ),
            if (recipe.cookTimeMinutes != null)
              _InfoRow(
                label: 'Cook time',
                value: '${recipe.cookTimeMinutes} min',
              ),
            const SizedBox(height: 16),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recipe.ingredients.map(
              (ing) => ListTile(
                title: Text(ing.name),
                subtitle: Text('${ing.quantity} ${ing.unit}'),
                leading: const Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(recipe.instructions),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final pantryProvider = context.read<PantryProvider>();
                      final missing = recipeProvider.validateRecipeAgainstPantry(
                        recipe: recipe,
                        pantry: pantryProvider.items,
                      );
                      if (missing.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Missing: ${missing.take(3).join(', ')}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cook this recipe?'),
                          content: const Text(
                            'Ingredients will be deducted from your pantry.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Cook'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      final deductions =
                          recipeProvider.buildDeductionPlanForRecipe(
                            recipe: recipe,
                            pantry: pantryProvider.items,
                          );
                      final success = await pantryProvider.deductMultipleItems(
                        deductions:
                            deductions
                                .map((d) => (id: d.pantryItemId, amount: d.amount))
                                .toList(),
                        source: 'recipe_${recipe.id}',
                        recipeId: recipe.id,
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recipe cooked! Stock updated.')),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not enough ingredients.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.kitchen),
                    label: const Text('Cook now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditRecipeScreen(recipe: recipe),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}