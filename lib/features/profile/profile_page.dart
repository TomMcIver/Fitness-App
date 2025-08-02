import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../models/user_profile.dart';
import '../../core/providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // form controllers
  final _formKey   = GlobalKey<FormState>();
  Gender? _gender;
  final _weightCtl = TextEditingController();
  final _heightCtl = TextEditingController();
  final _neckCtl   = TextEditingController();
  final _waistCtl  = TextEditingController();
  final _hipCtl    = TextEditingController();

  late final ProviderSubscription<UserProfile?> _sub;

  @override
  void initState() {
    super.initState();
    _hydrate(ref.read(userProfileProvider));

    _sub = ref.listenManual<UserProfile?>(userProfileProvider, (_, next) {
      _hydrate(next);
    });
  }

  @override
  void dispose() {
    _sub.close();
    _weightCtl.dispose();
    _heightCtl.dispose();
    _neckCtl.dispose();
    _waistCtl.dispose();
    _hipCtl.dispose();
    super.dispose();
  }

  // ---- helpers -------------------------------------------------------------
  void _hydrate(UserProfile? p) {
    if (p == null) return;
    setState(() {
      _gender        ??= p.gender;
      _weightCtl.text = p.weightKg.toString();
      _heightCtl.text = p.heightCm.toStringAsFixed(0);
      _neckCtl.text   = p.circumferences['neck'] ?.toString() ?? '';
      _waistCtl.text  = p.circumferences['waist']?.toString() ?? '';
      _hipCtl.text    = p.circumferences['hip']  ?.toString() ?? '';
    });
  }

  Widget _numField(TextEditingController ctl,
      {required String label,
      double? min,
      double? max,
      bool required = true}) {
    return TextFormField(
      controller: ctl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (!required && (value == null || value.isEmpty)) return null;
        final v = double.tryParse(value ?? '');
        if (v == null) return 'Enter a number';
        if (min != null && v < min) return 'Min $min';
        if (max != null && v > max) return 'Max $max';
        return null;
      },
    );
  }

  // ---- save ----------------------------------------------------------------
  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final g = _gender!;
    final weight = double.parse(_weightCtl.text);
    final height = double.parse(_heightCtl.text);
    final neck = double.parse(_neckCtl.text);
    final waist = double.parse(_waistCtl.text);

    final notifier = ref.read(userProfileProvider.notifier);
    
    // Set basic info
    notifier.setBasicInfo(gender: g, weightKg: weight, heightCm: height);

    // Update circumferences
    notifier.updateCircumference('neck', neck);
    notifier.updateCircumference('waist', waist);

    if (g == Gender.female) {
      final hip = double.parse(_hipCtl.text);
      notifier.updateCircumference('hip', hip);
    } else {
      // clear hip if previously set
      notifier.updateCircumference('hip', 0);
    }

    // Force a state update to trigger dependent providers
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Refresh the providers to ensure calculations are updated
    ref.invalidate(bmiProvider);
    ref.invalidate(bodyFatProvider);
    ref.invalidate(bodyFatCategoryProvider);

    // create rough calorie goal if missing
    if (ref.read(nutritionGoalProvider) == null) {
      final kcal = (weight * 30).round();
      ref.read(nutritionGoalProvider.notifier).state = NutritionGoal(
        calories: kcal,
        protein : weight * 1.6,
        carbs   : weight * 4,
        fat     : weight * 0.9,
      );
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile saved ✔')));
  }

  // ---- build ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bmi   = ref.watch(bmiProvider)?.toStringAsFixed(1);
    final bf    = ref.watch(bodyFatProvider)?.toStringAsFixed(1);
    final bfCat = ref.watch(bodyFatCategoryProvider);

    final isFemale = _gender == Gender.female;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsCard(bmi: bmi, bodyFat: bf, bodyFatCategory: bfCat),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<Gender>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: Gender.male,   child: Text('Male')),
                      DropdownMenuItem(value: Gender.female, child: Text('Female')),
                    ],
                    onChanged: (g) => setState(() {
                      _gender = g;
                      if (g != Gender.female) _hipCtl.clear();
                    }),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _numField(_weightCtl, label: 'Weight (kg)', min: 20,  max: 300),
                  const SizedBox(height: 12),
                  _numField(_heightCtl, label: 'Height (cm)', min: 100, max: 250),
                  const SizedBox(height: 12),
                  _numField(_neckCtl,  label: 'Neck (cm)', min: 10, max: 100),
                  const SizedBox(height: 12),
                  _numField(_waistCtl, label: 'Waist (cm)', min: 40, max: 200),
                  const SizedBox(height: 12),
                  if (isFemale)
                    _numField(_hipCtl, label: 'Hip (cm)', min: 50, max: 200),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- metric card -----------------------------------------------------------
class _MetricsCard extends StatelessWidget {
  final String? bmi, bodyFat, bodyFatCategory;
  const _MetricsCard({this.bmi, this.bodyFat, this.bodyFatCategory});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _metric('BMI',      bmi),
            _metric('Body Fat', bodyFat != null ? '$bodyFat%' : null),
            _metric('Category', bodyFatCategory),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String? value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value ?? '--',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}