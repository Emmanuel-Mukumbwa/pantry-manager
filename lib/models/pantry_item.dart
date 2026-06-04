import 'dart:convert';
import 'consumption_record.dart';

class PantryItem {
  PantryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    required this.expiryDate,
    required this.unit,
    required this.threshold,
    DateTime? addedDate,
    List<ConsumptionRecord>? consumptionHistory,
    this.lastUsedDate,
    this.pricePerUnit, // new
  }) : addedDate = addedDate ?? DateTime.now(),
       consumptionHistory = consumptionHistory ?? const <ConsumptionRecord>[];

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    final expiryRaw = json['expiryDate'] ?? json['expiry_date'];

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.parse(v as String);
    }

    final qtyRaw = json['quantity'];
    final quantity = (qtyRaw is num)
        ? qtyRaw.toDouble()
        : double.tryParse('$qtyRaw') ?? 0.0;

    final thresholdRaw = json['threshold'];
    final threshold = (thresholdRaw is num)
        ? thresholdRaw.toDouble()
        : double.tryParse('$thresholdRaw') ?? 1.0;

    final unit = (json['unit'] as String?) ?? 'pieces';
    final category = (json['category'] as String?) ?? 'Grains';

    final addedDate = parseDate(json['addedDate'] ?? json['added_date']);
    final lastUsedDateRaw = json['lastUsedDate'] ?? json['last_used_date'];
    final lastUsedDate = lastUsedDateRaw != null
        ? parseDate(lastUsedDateRaw)
        : null;

    double? pricePerUnit;
    final priceRaw = json['pricePerUnit'] ?? json['price_per_unit'];
    if (priceRaw != null) {
      pricePerUnit = (priceRaw is num) ? priceRaw.toDouble() : double.tryParse('$priceRaw');
    }

    final chRaw = json['consumptionHistory'] ?? json['consumption_history'];
    final consumptionHistory = <ConsumptionRecord>[];
    if (chRaw is List) {
      for (final e in chRaw) {
        if (e == null) continue;
        if (e is String || e is num) {
          final dt = parseDate(e);
          consumptionHistory.add(
            ConsumptionRecord(
              id: '',
              dateTime: dt,
              amount: 0.0,
              unit: unit,
              remainingQuantity: 0.0,
              source: 'legacy',
            ),
          );
          continue;
        }
        if (e is Map<String, dynamic>) {
          consumptionHistory.add(ConsumptionRecord.fromJson(e));
        }
      }
    }

    return PantryItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      quantity: quantity,
      category: category,
      expiryDate: parseDate(expiryRaw),
      unit: unit,
      threshold: threshold,
      addedDate: addedDate,
      consumptionHistory: consumptionHistory,
      lastUsedDate: lastUsedDate,
      pricePerUnit: pricePerUnit,
    );
  }

  String id;
  String name;
  double quantity;
  String category;
  DateTime expiryDate;
  String unit;
  double threshold;
  DateTime addedDate;
  List<ConsumptionRecord> consumptionHistory;
  DateTime? lastUsedDate;
  double? pricePerUnit; // price per single unit (e.g., $2.5 per kg)

  /// Total value of this item in inventory (quantity × pricePerUnit)
  double get totalValue => pricePerUnit != null ? quantity * pricePerUnit! : 0.0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'expiryDate': expiryDate.toIso8601String(),
      'unit': unit,
      'threshold': threshold,
      'addedDate': addedDate.toIso8601String(),
      'consumptionHistory': consumptionHistory.map((d) => d.toJson()).toList(),
      if (lastUsedDate != null) 'lastUsedDate': lastUsedDate!.toIso8601String(),
      if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
    };
  }

  PantryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? category,
    DateTime? expiryDate,
    String? unit,
    double? threshold,
    DateTime? addedDate,
    List<ConsumptionRecord>? consumptionHistory,
    DateTime? lastUsedDate,
    double? pricePerUnit,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      unit: unit ?? this.unit,
      threshold: threshold ?? this.threshold,
      addedDate: addedDate ?? this.addedDate,
      consumptionHistory: consumptionHistory ?? this.consumptionHistory,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    );
  }

  static String encodeItems(List<PantryItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static List<PantryItem> decodeItems(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <PantryItem>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((e) => PantryItem.fromJson(e))
        .toList();
  }
}