import 'package:uuid/uuid.dart';
import 'dart:math' as math;

const _uuid = Uuid();

class FoodItem {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    String? id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  }) : id = id ?? _uuid.v4();

  FoodItem copyWith({
    String? id,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }
}

class Meal {
  final String id;
  final String name;
  final DateTime timestamp;
  final List<FoodItem> items;

  Meal({
    String? id,
    required this.name,
    required this.timestamp,
    this.items = const [],
  }) : id = id ?? _uuid.v4();

  int get calories => items.fold(0, (s, f) => s + f.calories);
  double get protein => items.fold(0.0, (s, f) => s + f.protein);
  double get carbs   => items.fold(0.0, (s, f) => s + f.carbs);
  double get fat     => items.fold(0.0, (s, f) => s + f.fat);

  Meal copyWith({String? id, String? name, DateTime? timestamp, List<FoodItem>? items}) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
    );
  }
}

class DailyLog {
  final DateTime date;
  final List<Meal> meals;
  const DailyLog({required this.date, this.meals = const []});

  int    get calories => meals.fold(0,    (s, m) => s + m.calories);
  double get protein  => meals.fold(0.0,  (s, m) => s + m.protein);
  double get carbs    => meals.fold(0.0,  (s, m) => s + m.carbs);
  double get fat      => meals.fold(0.0,  (s, m) => s + m.fat);

  DailyLog copyWith({DateTime? date, List<Meal>? meals}) =>
      DailyLog(date: date ?? this.date, meals: meals ?? this.meals);
}

/// user-defined daily targets
class NutritionGoal {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  const NutritionGoal({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

// helper for % progress vs goal
class MacroProgress {
  final double calories, protein, carbs, fat;
  const MacroProgress({required this.calories, required this.protein, required this.carbs, required this.fat});
}
