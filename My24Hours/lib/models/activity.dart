class Activity {
  final int? id;
  final String title;
  final String category;
  final String date; // YYYY-MM-DD
  final int startMinute; // 0 to 1439
  final int endMinute; // 1 to 1440
  final int durationMinutes;

  Activity({
    this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date,
      'startMinute': startMinute,
      'endMinute': endMinute,
      'durationMinutes': durationMinutes,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      date: map['date'] as String,
      startMinute: map['startMinute'] as int,
      endMinute: map['endMinute'] as int,
      durationMinutes: map['durationMinutes'] as int,
    );
  }
}

class CategoryGoal {
  final String category;
  int targetDurationMinutes;
  double weight;

  CategoryGoal({
    required this.category,
    required this.targetDurationMinutes,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'targetDurationMinutes': targetDurationMinutes,
      'weight': weight,
    };
  }

  factory CategoryGoal.fromMap(Map<String, dynamic> map) {
    return CategoryGoal(
      category: map['category'] as String,
      targetDurationMinutes: map['targetDurationMinutes'] as int,
      weight: (map['weight'] as num).toDouble(),
    );
  }

  static List<CategoryGoal> defaultGoals = [
    CategoryGoal(category: 'Coding', targetDurationMinutes: 240, weight: 40.0),
    CategoryGoal(category: 'Quran', targetDurationMinutes: 60, weight: 20.0),
    CategoryGoal(category: 'English', targetDurationMinutes: 60, weight: 15.0),
    CategoryGoal(category: 'Exercise', targetDurationMinutes: 45, weight: 10.0),
    CategoryGoal(category: 'Namaz', targetDurationMinutes: 30, weight: 10.0),
    CategoryGoal(category: 'Personal habits', targetDurationMinutes: 30, weight: 5.0),
  ];
}
