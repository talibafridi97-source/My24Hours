import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/activity.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('daytrack24.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        startMinute INTEGER NOT NULL,
        endMinute INTEGER NOT NULL,
        durationMinutes INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE category_goals (
        category TEXT PRIMARY KEY,
        targetDurationMinutes INTEGER NOT NULL,
        weight REAL NOT NULL
      )
    ''');

    // Insert default category goals
    for (var goal in CategoryGoal.defaultGoals) {
      await db.insert('category_goals', goal.toMap());
    }
  }

  // Activities CRUD
  Future<int> insertActivity(Activity activity) async {
    final db = await database;
    return await db.insert('activities', activity.toMap());
  }

  Future<List<Activity>> getActivitiesForDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'activities',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'startMinute ASC',
    );
    return maps.map((m) => Activity.fromMap(m)).toList();
  }

  Future<List<Activity>> getActivitiesForDateRange(String startDate, String endDate) async {
    final db = await database;
    final maps = await db.query(
      'activities',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, startMinute ASC',
    );
    return maps.map((m) => Activity.fromMap(m)).toList();
  }

  Future<int> deleteActivity(int id) async {
    final db = await database;
    return await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  // Category Goals CRUD
  Future<List<CategoryGoal>> getCategoryGoals() async {
    final db = await database;
    final maps = await db.query('category_goals');
    if (maps.isEmpty) {
      for (var goal in CategoryGoal.defaultGoals) {
        await db.insert('category_goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return CategoryGoal.defaultGoals;
    }
    return maps.map((m) => CategoryGoal.fromMap(m)).toList();
  }

  Future<int> updateCategoryGoal(CategoryGoal goal) async {
    final db = await database;
    return await db.update(
      'category_goals',
      goal.toMap(),
      where: 'category = ?',
      whereArgs: [goal.category],
    );
  }

  Future<int> insertCategoryGoal(CategoryGoal goal) async {
    final db = await database;
    return await db.insert(
      'category_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteCategoryGoal(String category) async {
    final db = await database;
    return await db.delete(
      'category_goals',
      where: 'category = ?',
      whereArgs: [category],
    );
  }
}
