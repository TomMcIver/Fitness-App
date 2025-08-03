import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../models/user_profile.dart';
import '../models/measurement_entry.dart';   

// user profil state
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null);

  void setBasicInfo({
    required Gender gender,
    required double weightKg,
    required double heightCm,
  }) {
    state = (state ??
            UserProfile(
              gender: gender,
              weightKg: weightKg,
              heightCm: heightCm,
            ))
        .copyWith(gender: gender, weightKg: weightKg, heightCm: heightCm);
  }

  void updateCircumference(String name, double valueCm) {
    final cur = state;
    if (cur == null) return;
    final newCirc =
        Map<String, double>.from(cur.circumferences)..[name] = valueCm;
    state = cur.copyWith(circumferences: newCirc);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
        (ref) => UserProfileNotifier());

final bmiProvider             = Provider<double?>((ref) => ref.watch(userProfileProvider)?.bmi);
final bodyFatProvider         = Provider<double?>((ref) => ref.watch(userProfileProvider)?.bodyFatPercent);
final bodyFatCategoryProvider = Provider<String?>((ref) => ref.watch(userProfileProvider)?.bodyFatCategory);

// mersur history 
class MeasurementNotifier extends StateNotifier<List<MeasurementEntry>> {
  MeasurementNotifier() : super([]);

  // add a new weight / circumference entry
  void addEntry(MeasurementEntry entry) {
    state = [...state, entry]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // remove a specific measurement entry
  void removeEntry(MeasurementEntry entry) {
    state = state.where((e) => e.dateTime != entry.dateTime).toList();
  }

  // clear  measurement history
  void clearAll() {
    state = [];
  }

  //convenience: last *n* days of data  7 for weekly chart
  List<MeasurementEntry> entriesForPastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return state.where((e) => e.dateTime.isAfter(cutoff)).toList();
  }
}

final measurementHistoryProvider =
    StateNotifierProvider<MeasurementNotifier, List<MeasurementEntry>>(
        (ref) => MeasurementNotifier());

// nutrution sate
final nutritionGoalProvider = StateProvider<NutritionGoal?>((ref) => null);

class DailyLogNotifier extends StateNotifier<DailyLog> {
  DailyLogNotifier() : super(DailyLog(date: _today()));

  void _roll() {
    if (!_sameDay(state.date, DateTime.now())) {
      state = DailyLog(date: _today());
    }
  }

  void addMeal(Meal m) {
    _roll();
    state = state.copyWith(meals: [...state.meals, m]);
  }
}

final dailyLogProvider =
    StateNotifierProvider<DailyLogNotifier, DailyLog>(
        (ref) => DailyLogNotifier());

final macroProgressProvider = Provider<MacroProgress?>((ref) {
  final log  = ref.watch(dailyLogProvider);
  final goal = ref.watch(nutritionGoalProvider);
  if (goal == null) return null;

  double r(num v, num g) => g == 0 ? 0 : (v / g).clamp(0, 1);

  return MacroProgress(
    calories: r(log.calories, goal.calories),
    protein : r(log.protein,  goal.protein),
    carbs   : r(log.carbs,    goal.carbs),
    fat     : r(log.fat,      goal.fat),
  );
});

//  helpers 
DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;