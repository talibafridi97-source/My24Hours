import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../database/database_helper.dart';
import '../utils/time_utils.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Activity> _activities = [];
  List<CategoryGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final activities = await DatabaseHelper.instance.getActivitiesForDate(dateStr);
    final goals = await DatabaseHelper.instance.getCategoryGoals();
    setState(() {
      _activities = activities;
      _goals = goals;
      _isLoading = false;
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final timeResult = TimeUtils.calculateTimeAccounting(_activities);
    final productivityScore = TimeUtils.calculateProductivityScore(_activities, _goals);
    String formattedDate = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DayTrack 24 Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Date Selector Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Time Accounting Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Time Accounting (1,440 mins)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Chip(
                          label: Text('${timeResult.accountingPercentage.toStringAsFixed(1)}%'),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: timeResult.accountingPercentage / 100.0,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricItem(
                          'Accounted',
                          TimeUtils.formatHoursMinutes(timeResult.accountedMinutes),
                          Icons.access_time_filled,
                          Colors.blue,
                        ),
                        _buildMetricItem(
                          'Remaining',
                          TimeUtils.formatHoursMinutes(timeResult.remainingMinutes),
                          Icons.hourglass_empty,
                          Colors.orange,
                        ),
                      ],
                    ),
                    if (timeResult.overlapWarnings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: timeResult.overlapWarnings
                              .map((w) => Text('⚠️ $w', style: const TextStyle(fontSize: 12, color: Colors.brown)))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Productivity Score Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Productivity Score',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${productivityScore.toStringAsFixed(1)} / 100',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Independent score based on configurable category goals & weights.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    ..._goals.map((goal) {
                      int actualMins = _calculateCategoryActual(_activities, goal.category);
                      double completion = (actualMins / goal.targetDurationMinutes).clamp(0.0, 1.0);
                      double points = goal.weight * completion;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${goal.category} (${goal.weight.toInt()} pts max)',
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  '${TimeUtils.formatHoursMinutes(actualMins)} / ${TimeUtils.formatHoursMinutes(goal.targetDurationMinutes)} (${points.toStringAsFixed(1)} pts)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: completion,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.green,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Navigation to Log Activity
            ElevatedButton.icon(
              onPressed: () => widget.onNavigateTab(1),
              icon: const Icon(Icons.add_circle),
              label: const Text('Log Activities for Today'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCategoryActual(List<Activity> activities, String category) {
    int sum = 0;
    for (var act in activities) {
      if (act.category == category && act.startMinute >= 0 && act.endMinute <= 1440 && act.startMinute < act.endMinute) {
        sum += act.durationMinutes;
      }
    }
    return sum;
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
