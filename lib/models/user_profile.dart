import 'dart:math' as math;

enum Gender { male, female, other }

class UserProfile {
  final Gender gender;
  final double weightKg;
  final double heightCm;
  final Map<String, double> circumferences;
  final DateTime updatedAt;

   UserProfile({
    required this.gender,
    required this.weightKg,
    required this.heightCm,
    this.circumferences = const {},
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  double get bmi => weightKg / math.pow(heightCm / 100, 2);

  double? get bodyFatPercent {
    final neck  = circumferences['neck'];
    final waist = circumferences['waist'];
    if (gender == Gender.male) {
      if (neck == null || waist == null) return null;
      return 86.010 * _log10(waist - neck) - 70.041 * _log10(heightCm) + 36.76;
    } else {
      final hip = circumferences['hip'];
      if (neck == null || waist == null || hip == null) return null;
      return 163.205 * _log10(waist + hip - neck) -
             97.684 * _log10(heightCm) - 78.387;
    }
  }

  String? get bodyFatCategory {
    final bf = bodyFatPercent;
    if (bf == null) return null;
    if (gender == Gender.male) {
      if (bf < 6)  return 'Essential';
      if (bf < 14) return 'Athlete';
      if (bf < 18) return 'Fit';
      if (bf < 25) return 'Average';
      return 'Obese';
    } else {
      if (bf < 14) return 'Essential';
      if (bf < 21) return 'Athlete';
      if (bf < 25) return 'Fit';
      if (bf < 32) return 'Average';
      return 'Obese';
    }
  }

  UserProfile copyWith({
    Gender? gender,
    double? weightKg,
    double? heightCm,
    Map<String, double>? circumferences,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      circumferences: circumferences ?? this.circumferences,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  double _log10(num x) => math.log(x) / math.ln10;
}
