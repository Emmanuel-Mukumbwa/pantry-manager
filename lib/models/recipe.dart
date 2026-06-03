import 'recipe_ingredient.dart';

class Recipe {
  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.servings,
    required this.ingredients,
    required this.instructions, 
    required this.category,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final String instructions;
  final String category;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final DateTime createdAt;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.parse(v as String);
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return Recipe(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      servings: parseInt(json['servings']),
      ingredients:
          (json['ingredients'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(RecipeIngredient.fromJson)
              .toList(growable: false) ??
          const <RecipeIngredient>[],
      instructions: (json['instructions'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'General',
      prepTimeMinutes:
          json['prepTimeMinutes'] as int? ??
          (json['prep_time_minutes'] as int?),
      cookTimeMinutes:
          json['cookTimeMinutes'] as int? ??
          (json['cook_time_minutes'] as int?),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
    'servings': servings,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'instructions': instructions,
    'category': category,
    'prepTimeMinutes': prepTimeMinutes,
    'cookTimeMinutes': cookTimeMinutes,
    'createdAt': createdAt.toIso8601String(),
  };
}
