import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/providers.dart';
import '../../models/measurement_entry.dart';
import '../../models/user_profile.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(measurementHistoryProvider)
        .where((e) => e.dateTime.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _HistoryPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _AddMeasurementDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: data.isEmpty
          ? const Center(child: Text('No data yet — add a measurement!'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ChartCard(
                  title: 'Weight (kg)',
                  data: data,
                  valueSelector: (e) => e.weightKg,
                  yAxisSuffix: ' kg',
                ),
                const SizedBox(height: 24),
                _ChartCard(
                  title: 'Body-Fat %',
                  data: data,
                  valueSelector: (e) => e.bodyFatPercent,
                  yAxisSuffix: '%',
                ),
              ],
            ),
    );
  }
}

//  chart widget
class _ChartCard extends StatelessWidget {
  final String title;
  final List<MeasurementEntry> data;
  final double? Function(MeasurementEntry) valueSelector;
  final String yAxisSuffix;
  
  const _ChartCard({
    required this.title,
    required this.data,
    required this.valueSelector,
    required this.yAxisSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = _toSpots(data, valueSelector);
    
    if (spots.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('No $title data available'),
          ),
        ),
      );
    }

    // calculate min and max for Y axis
    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    
    // handle case where all values are the same
    final range = maxY - minY;
    final yPadding = range > 0 ? range * 0.1 : 1.0; // 10% padding or default
    final interval = range > 0 ? range / 4 : 1.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.6,
              child: LineChart(
                LineChartData(
                  minY: minY - yPadding,
                  maxY: maxY + yPadding,
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                      left: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          
                          final date = data[index].dateTime;
                          final month = date.month.toString().padLeft(2, '0');
                          final day = date.day.toString().padLeft(2, '0');
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '$month/$day',
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toStringAsFixed(1)}$yAxisSuffix',
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: theme.colorScheme.primary,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      spots: spots,
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _toSpots(
    List<MeasurementEntry> entries,
    double? Function(MeasurementEntry) selector,
  ) {
    return [
      for (int i = 0; i < entries.length; i++)
        if (selector(entries[i]) != null)
          FlSpot(i.toDouble(), selector(entries[i])!),
    ];
  }
}

//  add measurement dialog 
class _AddMeasurementDialog extends ConsumerStatefulWidget {
  const _AddMeasurementDialog({super.key});
  @override
  ConsumerState<_AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends ConsumerState<_AddMeasurementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weight  = TextEditingController();
  final _neck    = TextEditingController();
  final _waist   = TextEditingController();
  final _hip     = TextEditingController();

  @override
  void dispose() {
    _weight.dispose();
    _neck.dispose();
    _waist.dispose();
    _hip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.read(userProfileProvider);
    final isFemale = profile?.gender == Gender.female;

    return AlertDialog(
      title: const Text('Add measurement'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numField(_weight, 'Weight (kg)', min: 20, max: 300),
              _numField(_neck,   'Neck (cm)', min: 10, max: 100),
              _numField(_waist,  'Waist (cm)', min: 40, max: 200),
              if (isFemale) _numField(_hip, 'Hip (cm)', min: 50, max: 200),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            final entry = MeasurementEntry(
              dateTime : DateTime.now(),
              weightKg : double.parse(_weight.text),
              neckCm   : double.parse(_neck.text),
              waistCm  : double.parse(_waist.text),
              hipCm    : isFemale ? double.parse(_hip.text) : null,
              heightCm : profile?.heightCm ?? 170,
              gender   : profile?.gender ?? Gender.male,
            );

            ref.read(measurementHistoryProvider.notifier).addEntry(entry);
            Navigator.of(context).pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Measurement added ✔')),
            );
          },
        ),
      ],
    );
  }

  Widget _numField(TextEditingController c, String label, {double? min, double? max}) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            final v = double.tryParse(value);
            if (v == null) return 'Enter a number';
            if (min != null && v < min) return 'Min $min';
            if (max != null && v > max) return 'Max $max';
            return null;
          },
        ),
      );
}

//  history page ────────────
class _HistoryPage extends ConsumerWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allData = ref.watch(measurementHistoryProvider);
    
    if (allData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Measurement History')),
        body: const Center(
          child: Text('No measurements yet'),
        ),
      );
    }

    // data by month
    final groupedData = _groupByMonth(allData);
    final sortedMonths = groupedData.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // ost recent first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement History'),
        actions: [
          if (allData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearAllDialog(context, ref),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: sortedMonths.length,
        itemBuilder: (context, index) {
          final monthKey = sortedMonths[index];
          final monthData = groupedData[monthKey]!
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // recent first
          
          return _MonthSection(
            monthYear: monthKey,
            entries: monthData,
            onDelete: (entry) {
              ref.read(measurementHistoryProvider.notifier).removeEntry(entry);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Measurement deleted')),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<MeasurementEntry>> _groupByMonth(List<MeasurementEntry> entries) {
    final Map<String, List<MeasurementEntry>> grouped = {};
    
    for (final entry in entries) {
      final key = '${_getMonthName(entry.dateTime.month)} ${entry.dateTime.year}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    
    return grouped;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will delete all measurement history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(measurementHistoryProvider.notifier).clearAll();
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to progress page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All history cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// month section widget 
class _MonthSection extends StatelessWidget {
  final String monthYear;
  final List<MeasurementEntry> entries;
  final Function(MeasurementEntry) onDelete;

  const _MonthSection({
    required this.monthYear,
    required this.entries,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            monthYear,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text('${entries.length} measurements'),
          initiallyExpanded: entries.first.dateTime.month == DateTime.now().month &&
                            entries.first.dateTime.year == DateTime.now().year,
          children: entries.map((entry) => _MeasurementTile(
            entry: entry,
            onDelete: () => onDelete(entry),
          )).toList(),
        ),
      ),
    );
  }
}

//  measurement tile widget 
class _MeasurementTile extends StatelessWidget {
  final MeasurementEntry entry;
  final VoidCallback onDelete;

  const _MeasurementTile({
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayName = _getDayName(entry.dateTime.weekday);
    final day = entry.dateTime.day.toString().padLeft(2, '0');
    final time = '${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}';
    
    return Dismissible(
      key: Key(entry.dateTime.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            day,
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text('$dayName, $time'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight: ${entry.weightKg.toStringAsFixed(1)} kg'),
            if (entry.bodyFatPercent != null)
              Text('Body Fat: ${entry.bodyFatPercent!.toStringAsFixed(1)}%'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.bodyFatPercent != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBodyFatColor(entry.bodyFatPercent!, entry.gender),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getBodyFatCategory(entry.bodyFatPercent!, entry.gender),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Color _getBodyFatColor(double bf, Gender gender) {
    final thresholds = gender == Gender.female
        ? [14.0, 21.0, 25.0, 32.0] // Female thresholds
        : [6.0, 14.0, 18.0, 25.0]; // Male thresholds
    
    if (bf < thresholds[0]) return Colors.blue;
    if (bf < thresholds[1]) return Colors.green;
    if (bf < thresholds[2]) return Colors.orange;
    if (bf < thresholds[3]) return Colors.deepOrange;
    return Colors.red;
  }

  String _getBodyFatCategory(double bf, Gender gender) {
    final thresholds = gender == Gender.female
        ? [14.0, 21.0, 25.0, 32.0]
        : [6.0, 14.0, 18.0, 25.0];
    
    if (bf < thresholds[0]) return 'Essential';
    if (bf < thresholds[1]) return 'Athletic';
    if (bf < thresholds[2]) return 'Fit';
    if (bf < thresholds[3]) return 'Average';
    return 'High';
  }
}