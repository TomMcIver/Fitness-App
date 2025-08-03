import 'dart:math' as math;
import 'user_profile.dart';  

class MeasurementEntry {
  final DateTime dateTime;
  final double weightKg;
  final double heightCm;
  final double neckCm;
  final double waistCm;
  final double? hipCm;
  final Gender gender;

  MeasurementEntry({
    required this.dateTime,
    required this.weightKg,
    required this.heightCm,
    required this.neckCm,
    required this.waistCm,
    this.hipCm,
    required this.gender,
  });

  // cal body fat percentage using navy formula
  double? get bodyFatPercent {
    
    if (neckCm <= 0 || waistCm <= 0 || heightCm <= 0) return null;
    
    
    if (gender == Gender.female && (hipCm == null || hipCm! <= 0)) return null;
    
    
    if (waistCm <= neckCm) return null;

    try {
      double result;
      
      if (gender == Gender.male) {
        // male formula: 86.010 × log10(waist - neck) - 70.041 × log10(height) + 36.76
        result = 86.010 * _log10(waistCm - neckCm) - 
                70.041 * _log10(heightCm) + 
                36.76;
      } else {
        //female formula: 163.205 × log10(waist + hip - neck) - 97.684 × log10(height) - 78.387
        result = 163.205 * _log10(waistCm + hipCm! - neckCm) - 
                97.684 * _log10(heightCm) - 
                78.387;
      }
      
      
      return result.clamp(2.0, 50.0);
    } catch (e) {
      return null;
    }
  }

  // helper for base 10 logarithm
  double _log10(double x) => math.log(x) / math.ln10;

  //body fat category based on percentage
  String? get bodyFatCategory {
    final bf = bodyFatPercent;
    if (bf == null) return null;

    if (gender == Gender.male) {
      if (bf < 6) return 'Essential';
      if (bf < 14) return 'Athletic';
      if (bf < 18) return 'Fit';
      if (bf < 25) return 'Average';
      return 'High';
    } else {
      if (bf < 14) return 'Essential';
      if (bf < 21) return 'Athletic';
      if (bf < 25) return 'Fit';
      if (bf < 32) return 'Average';
      return 'High';
    }
  }

  // copy with updated values
  MeasurementEntry copyWith({
    DateTime? dateTime,
    double? weightKg,
    double? heightCm,
    double? neckCm,
    double? waistCm,
    double? hipCm,
    Gender? gender,
  }) {
    return MeasurementEntry(
      dateTime: dateTime ?? this.dateTime,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      neckCm: neckCm ?? this.neckCm,
      waistCm: waistCm ?? this.waistCm,
      hipCm: hipCm ?? this.hipCm,
      gender: gender ?? this.gender,
    );
  }

  // convert to json
  Map<String, dynamic> toJson() => {
    'dateTime': dateTime.toIso8601String(),
    'weightKg': weightKg,
    'heightCm': heightCm,
    'neckCm': neckCm,
    'waistCm': waistCm,
    'hipCm': hipCm,
    'gender': gender.name,
  };

  /// create from json
  factory MeasurementEntry.fromJson(Map<String, dynamic> json) {
    return MeasurementEntry(
      dateTime: DateTime.parse(json['dateTime']),
      weightKg: json['weightKg'].toDouble(),
      heightCm: json['heightCm'].toDouble(),
      neckCm: json['neckCm'].toDouble(),
      waistCm: json['waistCm'].toDouble(),
      hipCm: json['hipCm']?.toDouble(),
      gender: Gender.values.firstWhere((g) => g.name == json['gender']),
    );
  }
}