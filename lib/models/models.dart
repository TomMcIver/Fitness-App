// Core domain models for NutriPulse.
// Keep them free of UI / storage code so they can be reused across layers.

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// A single ingredient or food portion – e.g. "Skinless Chicken Breast 150 g".
// ---------------------------------------------------------------------------
class FoodItem {
  final String id;
  final String name;
  final int calories; // kcal per portion
  final double protein; // grams
  final double carbs;   // grams
  final double fat;     // grams

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

// ---------------------------------------------------------------------------
// A meal = any collection of FoodItems eaten at a single time (breakfast, snack).
// ---------------------------------------------------------------------------
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

  // Aggregated macros for the meal ------------------------------------------
  int get calories => items.fold(0, (sum, f) => sum + f.calories);
  double get protein => items.fold(0.0, (sum, f) => sum + f.protein);
  double get carbs => items.fold(0.0, (sum, f) => sum + f.carbs);
  double get fat => items.fold(0.0, (sum, f) => sum + f.fat);

  Meal copyWith({
    String? id,
    String? name,
    DateTime? timestamp,
    List<FoodItem>? items,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
    );
  }
}

// ---------------------------------------------------------------------------
// A single day’s log containing multiple meals.
// ---------------------------------------------------------------------------
class DailyLog {
  final DateTime date; // midnight in local TZ
  final List<Meal> meals;

  const DailyLog({required this.date, this.meals = const []});

  // Daily totals ------------------------------------------------------------
  int get calories => meals.fold(0, (sum, m) => sum + m.calories);
  double get protein => meals.fold(0.0, (sum, m) => sum + m.protein);
  double get carbs => meals.fold(0.0, (sum, m) => sum + m.carbs);
  double get fat => meals.fold(0.0, (sum, m) => sum + m.fat);

  DailyLog copyWith({DateTime? date, List<Meal>? meals}) {
    return DailyLog(date: date ?? this.date, meals: meals ?? this.meals);
  }
}

// ---------------------------------------------------------------------------
// User‑defined daily macro targets (optional – null means no goal set).
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Helper used by providers to expose percentage progress vs goal.
// ---------------------------------------------------------------------------
class MacroProgress {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MacroProgress({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
