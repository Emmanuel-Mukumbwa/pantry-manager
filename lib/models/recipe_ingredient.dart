class RecipeIngredient {
  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final double quantity; 
  final String unit;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;

    return RecipeIngredient(
      name: (json['name'] as String?) ?? '',
      quantity: parseDouble(json['quantity']),
      unit: (json['unit'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'quantity': quantity,
    'unit': unit,
  };
}
