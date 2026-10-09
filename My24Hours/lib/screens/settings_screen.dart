import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<CategoryGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await DatabaseHelper.instance.getCategoryGoals();
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  Future<void> _updateGoal(CategoryGoal goal) async {
    await DatabaseHelper.instance.updateCategoryGoal(goal);
    _loadGoals();
  }

  Future<void> _deleteCategory(String category) async {
    await DatabaseHelper.instance.deleteCategoryGoal(category);
    _loadGoals();
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController(text: '60');
    final weightController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name (e.g. Reading, Gym)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Duration (minutes)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Category Weight (points out of 100)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = nameController.text.trim();
                int? target = int.tryParse(targetController.text.trim());
                double? weight = double.tryParse(weightController.text.trim());
                if (name.isNotEmpty && target != null && weight != null) {
                  final newGoal = CategoryGoal(
                    category: name,
                    targetDurationMinutes: target,
                    weight: weight,
                  );
                  final nav = Navigator.of(context);
                  await DatabaseHelper.instance.insertCategoryGoal(newGoal);
                  if (!mounted) return;
                  nav.pop();
                  _loadGoals();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditGoalDialog(CategoryGoal goal) {
    final targetController = TextEditingController(text: goal.targetDurationMinutes.toString());
    final weightController = TextEditingController(text: goal.weight.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Configure ${goal.category}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Duration (minutes)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Category Weight (points out of 100)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                int? target = int.tryParse(targetController.text.trim());
                double? weight = double.tryParse(weightController.text.trim());
                if (target != null && weight != null) {
                  goal.targetDurationMinutes = target;
                  goal.weight = weight;
                  final nav = Navigator.of(context);
                  await _updateGoal(goal);
                  if (!mounted) return;
                  nav.pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalWeight = _goals.fold(0.0, (sum, g) => sum + g.weight);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Goal Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
            tooltip: 'Add Custom Category',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: totalWeight == 100.0 ? Colors.green.shade50 : Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          totalWeight == 100.0 ? Icons.check_circle : Icons.warning,
                          color: totalWeight == 100.0 ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Total Weight: ${totalWeight.toStringAsFixed(1)} / 100 points',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: totalWeight == 100.0 ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Custom Categories & Timetable',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Category'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._goals.map((goal) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(goal.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Target: ${goal.targetDurationMinutes} mins • Weight: ${goal.weight.toInt()} pts'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditGoalDialog(goal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteCategory(goal.category),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
