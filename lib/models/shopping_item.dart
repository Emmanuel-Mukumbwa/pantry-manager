class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isPurchased = false,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final bool isPurchased;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'isPurchased': isPurchased,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String, 
    isPurchased: json['isPurchased'] as bool? ?? false,
  );

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    bool? isPurchased,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
