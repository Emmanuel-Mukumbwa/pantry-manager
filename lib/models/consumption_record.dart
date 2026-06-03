class ConsumptionRecord {
  ConsumptionRecord({
    required this.id,
    required this.dateTime,
    required this.amount,
    required this.unit,
    required this.remainingQuantity,
    required this.source,
    this.itemId,
    this.recipeId,
  });

  final String id;
  final DateTime dateTime;
  final double amount;
  final String unit;
  final double remainingQuantity;
  final String source;
  final String? itemId;
  final String? recipeId;

  factory ConsumptionRecord.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.parse(v as String);
    }

    return ConsumptionRecord(
      id: (json['id'] as String?) ?? '',
      dateTime: parseDate(json['dateTime'] ?? json['date_time']),
      amount: parseDouble(json['amount']),
      unit: (json['unit'] as String?) ?? '',
      remainingQuantity: parseDouble(
        json['remainingQuantity'] ?? json['remaining_quantity'],
      ),
      source: (json['source'] as String?) ?? 'unknown',
      itemId: json['itemId'] as String?,
      recipeId: json['recipeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'amount': amount,
      'unit': unit,
      'remainingQuantity': remainingQuantity,
      'source': source,
      if (itemId != null) 'itemId': itemId,
      if (recipeId != null) 'recipeId': recipeId,
    };
  }
}