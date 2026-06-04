import 'package:flutter/material.dart';
import '../models/recipe.dart';

Future<Recipe?> showRecipeSearchBottomSheet(BuildContext context, List<Recipe> allRecipes, {List<String>? excludeRecipeIds}) async {
  return showModalBottomSheet<Recipe>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => RecipeSearchBottomSheet(allRecipes: allRecipes, excludeRecipeIds: excludeRecipeIds),
  );
}

class RecipeSearchBottomSheet extends StatefulWidget {
  const RecipeSearchBottomSheet({super.key, required this.allRecipes, this.excludeRecipeIds});
  final List<Recipe> allRecipes;
  final List<String>? excludeRecipeIds;

  @override
  State<RecipeSearchBottomSheet> createState() => _RecipeSearchBottomSheetState();
}

class _RecipeSearchBottomSheetState extends State<RecipeSearchBottomSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  List<String> get _categories {
    final cats = <String>{};
    for (final r in widget.allRecipes) {
      cats.add(r.category);
    }
    return cats.toList()..sort();
  }

  List<Recipe> get _filteredRecipes {
    var filtered = widget.allRecipes.where((r) => widget.excludeRecipeIds == null || !widget.excludeRecipeIds!.contains(r.id)).toList();
    if (_query.isNotEmpty) {
      filtered = filtered.where((r) => r.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    if (_selectedCategory != null) {
      filtered = filtered.where((r) => r.category == _selectedCategory).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                    );
                  }
                  final cat = _categories[i - 1];
                  return FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredRecipes.length,
              itemBuilder: (ctx, index) {
                final recipe = _filteredRecipes[index];
                return ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: Text(recipe.name),
                  subtitle: Text('${recipe.category} • ${recipe.servings} servings • Prep: ${recipe.prepTimeMinutes ?? 0} min'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, recipe),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}