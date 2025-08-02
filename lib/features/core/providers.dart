// Riverpod providers – keep business logic here; widgets should stay dumb.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// User‑specified goal (can be null if the user hasn’t set targets yet).
// ---------------------------------------------------------------------------
final nutritionGoalProvider = StateProvider<NutritionGoal?>((ref) => null);

// ---------------------------------------------------------------------------
// Daily log – StateNotifier holds mutable list of meals for today.
// ---------------------------------------------------------------------------
class DailyLogNotifier extends StateNotifier<DailyLog> {
  DailyLogNotifier() : super(DailyLog(date: _today()));

  // Ensure each new day starts with a fresh log.
  void _rollIfNeeded() {
    if (!_isSameDay(state.date, DateTime.now())) {
      state = DailyLog(date: _today());
    }
  }

  void addMeal(Meal meal) {
    _rollIfNeeded();
    state = state.copyWith(meals: [...state.meals, meal]);
  }

  void removeMeal(String mealId) {
    _rollIfNeeded();
    state = state.copyWith(
      meals: state.meals.where((m) => m.id != mealId).toList(),
    );
  }

  void updateMeal(Meal updated) {
    _rollIfNeeded();
    state = state.copyWith(
      meals: state.meals.map((m) => m.id == updated.id ? updated : m).toList(),
    );
  }

  void resetManually(DateTime date) {
    state = DailyLog(date: date);
  }
}

final dailyLogProvider = StateNotifierProvider<DailyLogNotifier, DailyLog>(
  (ref) => DailyLogNotifier(),
);

// ---------------------------------------------------------------------------
// Derived provider: macro progress as 0‑1 ratios (null if no goal).
// ---------------------------------------------------------------------------
final macroProgressProvider = Provider<MacroProgress?>((ref) {
  final log = ref.watch(dailyLogProvider);
  final goal = ref.watch(nutritionGoalProvider);
  if (goal == null) return null;

  double _ratio(num value, num goal) => goal == 0 ? 0 : (value / goal).clamp(0, 1);
  return MacroProgress(
    calories: _ratio(log.calories, goal.calories),
    protein: _ratio(log.protein, goal.protein),
    carbs: _ratio(log.carbs, goal.carbs),
    fat: _ratio(log.fat, goal.fat),
  );
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
