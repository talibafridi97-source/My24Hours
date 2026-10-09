import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../database/database_helper.dart';
import '../utils/time_utils.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Activity> _activities = [];
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final activities = await DatabaseHelper.instance.getActivitiesForDate(dateStr);
    final goals = await DatabaseHelper.instance.getCategoryGoals();
    List<String> cats = goals.map((g) => g.category).toList();
    if (!cats.contains('Other')) cats.add('Other');
    setState(() {
      _activities = activities;
      _categories = cats;
      _isLoading = false;
    });
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
      _loadActivities();
    }
  }

  void _showAddActivityDialog() {
    final titleController = TextEditingController();
    String selectedCategory = _categories.isNotEmpty ? _categories[0] : 'Other';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int startMin = startTime.hour * 60 + startTime.minute;
            int endMin = endTime.hour * 60 + endTime.minute;
            int duration = endMin - startMin;

            return AlertDialog(
              title: const Text('Log Activity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Activity Title'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text('Start: ${startTime.format(context)}'),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setDialogState(() => startTime = picked);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text('End: ${endTime.format(context)}'),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setDialogState(() => endTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${TimeUtils.formatHoursMinutes(duration > 0 ? duration : 0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: duration > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    if (duration <= 0)
                      const Text(
                        'End time must be after start time!',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: duration <= 0 || titleController.text.trim().isEmpty
                      ? null
                      : () async {
                          final newActivity = Activity(
                            title: titleController.text.trim(),
                            category: selectedCategory,
                            date: DateFormat('yyyy-MM-dd').format(_selectedDate),
                            startMinute: startMin,
                            endMinute: endMin,
                            durationMinutes: duration,
                          );
                          final nav = Navigator.of(context);
                          await DatabaseHelper.instance.insertActivity(newActivity);
                          if (!mounted) return;
                          nav.pop();
                          _loadActivities();
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteActivity(int id) async {
    await DatabaseHelper.instance.deleteActivity(id);
    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);
    final timeResult = TimeUtils.calculateTimeAccounting(_activities);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Accounted: ${timeResult.accountingPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activities.isEmpty
                    ? const Center(child: Text('No activities logged for this date. Tap + to add.'))
                    : ListView.builder(
                        itemCount: _activities.length,
                        itemBuilder: (context, index) {
                          final act = _activities[index];
                          String startTimeStr = _formatMinute(act.startMinute);
                          String endTimeStr = _formatMinute(act.endMinute);
                          return Dismissible(
                            key: Key(act.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              if (act.id != null) _deleteActivity(act.id!);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(act.category.isNotEmpty ? act.category.substring(0, 1) : 'A'),
                                ),
                                title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('$startTimeStr - $endTimeStr (${TimeUtils.formatHoursMinutes(act.durationMinutes)}) • ${act.category}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () {
                                    if (act.id != null) _deleteActivity(act.id!);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityDialog,
        tooltip: 'Add Activity',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatMinute(int minutes) {
    int h = minutes ~/ 60;
    int m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
