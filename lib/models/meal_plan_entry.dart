enum MealType { breakfast, lunch, dinner }

enum MealStatus { planned, cooked, skipped }

class MealPlanEntry {
  MealPlanEntry({
    required this.id,
    required this.date, 
    required this.mealType,
    required this.recipeId,
    required this.status,
    this.notes,
  });

  final String id;
  final DateTime date; // date-only (yyyy-mm-dd)
  final MealType mealType;
  final String recipeId;
  final MealStatus status;
  final String? notes;

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.parse(v as String);
    }

    String parseMealType(dynamic v) => '$v';
    String parseStatus(dynamic v) => '$v';

    MealType mealType = MealType.breakfast;
    final mt = parseMealType(json['mealType'] ?? json['meal_type']);
    if (mt == 'lunch') mealType = MealType.lunch;
    if (mt == 'dinner') mealType = MealType.dinner;

    MealStatus status = MealStatus.planned;
    final st = parseStatus(json['status']);
    if (st == 'cooked') status = MealStatus.cooked;
    if (st == 'skipped') status = MealStatus.skipped;

    return MealPlanEntry(
      id: (json['id'] as String?) ?? '',
      date: parseDate(json['date']),
      mealType: mealType,
      recipeId:
          (json['recipeId'] as String?) ?? (json['recipe_id'] as String?) ?? '',
      status: status,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'mealType': switch (mealType) {
      MealType.breakfast => 'breakfast',
      MealType.lunch => 'lunch',
      MealType.dinner => 'dinner',
    },
    'recipeId': recipeId,
    'status': switch (status) {
      MealStatus.planned => 'planned',
      MealStatus.cooked => 'cooked',
      MealStatus.skipped => 'skipped',
    },
    'notes': notes,
  };
}
 