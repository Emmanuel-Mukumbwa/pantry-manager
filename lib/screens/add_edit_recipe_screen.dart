import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../providers/recipe_provider.dart';
import '../providers/pantry_provider.dart';

class AddEditRecipeScreen extends StatefulWidget {
  const AddEditRecipeScreen({super.key, this.recipe});

  final Recipe? recipe;

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _servingsController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _category = 'General';
  int? _prepTime;
  int? _cookTime;

  final List<RecipeIngredient> _ingredients = [];
  final List<String> _categories = const [
    'General', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.name;
      _descController.text = widget.recipe!.description;
      _servingsController.text = widget.recipe!.servings.toString();
      _instructionsController.text = widget.recipe!.instructions;
      _category = widget.recipe!.category;
      _prepTime = widget.recipe!.prepTimeMinutes;
      _cookTime = widget.recipe!.cookTimeMinutes;
      _ingredients.addAll(widget.recipe!.ingredients);
    }
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (ctx) {
        final pantryProvider = Provider.of<PantryProvider>(ctx, listen: false);
        final pantryItems = pantryProvider.items;
        String? selectedItemId;
        double quantity = 1.0;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final selectedItem = selectedItemId != null
                ? pantryItems.firstWhere((i) => i.id == selectedItemId)
                : null;
            return AlertDialog(
              title: const Text('Add ingredient from pantry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select pantry item'),
                    value: selectedItemId,
                    items: pantryItems.map((item) {
                      return DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (${item.quantity} ${item.unit})'),
                      );
                    }).toList(),
                    onChanged: (value) => setStateDialog(() => selectedItemId = value),
                  ),
                  if (selectedItem != null) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: quantity.toString(),
                      decoration: InputDecoration(
                        labelText: 'Quantity (${selectedItem.unit})',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => quantity = double.tryParse(v) ?? 0,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (selectedItemId != null && quantity > 0) {
                      final item = pantryItems.firstWhere((i) => i.id == selectedItemId);
                      setState(() {
                        _ingredients.add(RecipeIngredient(
                          name: item.name,
                          quantity: quantity,
                          unit: item.unit,
                        ));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Recipe' : 'New Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: _servingsController, decoration: const InputDecoration(labelText: 'Servings'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _prepTime?.toString() ?? ''),
                    onChanged: (v) => _prepTime = int.tryParse(v),
                    decoration: const InputDecoration(labelText: 'Prep time (min)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _cookTime?.toString() ?? ''),
                    onChanged: (v) => _cookTime = int.tryParse(v),
                    decoration: const InputDecoration(labelText: 'Cook time (min)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ..._ingredients.map(
              (ing) => ListTile(
                title: Text(ing.name, style: const TextStyle(color: Colors.black87)),
                subtitle: Text('${ing.quantity} ${ing.unit}', style: const TextStyle(color: Colors.black54)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _ingredients.remove(ing)),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: const Text('Add ingredient from pantry'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(labelText: 'Instructions'),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final servings = int.tryParse(_servingsController.text.trim()) ?? 1;
                if (name.isEmpty || _ingredients.isEmpty) return;
                final recipeProvider = context.read<RecipeProvider>();
                if (isEditing) {
                  await recipeProvider.updateRecipe(
                    id: widget.recipe!.id,
                    name: name,
                    description: _descController.text.trim(),
                    servings: servings,
                    ingredients: _ingredients,
                    instructions: _instructionsController.text.trim(),
                    category: _category,
                    prepTimeMinutes: _prepTime,
                    cookTimeMinutes: _cookTime,
                  );
                } else {
                  await recipeProvider.addRecipe(
                    name: name,
                    description: _descController.text.trim(),
                    servings: servings,
                    ingredients: _ingredients,
                    instructions: _instructionsController.text.trim(),
                    category: _category,
                    prepTimeMinutes: _prepTime,
                    cookTimeMinutes: _cookTime,
                  );
                }
                if (mounted) Navigator.pop(context);
              },
              child: Text(isEditing ? 'Update Recipe' : 'Save Recipe'),
            ),
          ],
        ),
      ),
    );
  }
}