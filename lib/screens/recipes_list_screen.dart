import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';
import 'add_edit_recipe_screen.dart';

class RecipesListScreen extends StatelessWidget {
  const RecipesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = context.watch<RecipeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Recipes')),
      body:
          recipeProvider.recipes.isEmpty
              ? const Center(
                child: Text('No recipes yet. Tap + to add one.'),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recipeProvider.recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipeProvider.recipes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: Text(recipe.name),
                      subtitle: Text('${recipe.servings} servings • ${recipe.category}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditRecipeScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}