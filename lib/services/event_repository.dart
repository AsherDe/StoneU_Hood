import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

class EventRepository {
  static Database? _database;
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calendar.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events(
            id TEXT PRIMARY KEY,
            title TEXT,
            notes TEXT,
            startTime TEXT,
            endTime TEXT,
            reminderMinutes TEXT,
            color TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE settings(
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        }
      }
    );
  }

  Future<void> setStartDate(DateTime startDate) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': 'start_date',
        'value': startDate.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getStartDate() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['start_date'],
    );
    
    if (maps.isEmpty) return null;
    return DateTime.parse(maps.first['value']);
  }

  Future<void> insertEvent(CalendarEvent event) async {
    final db = await database;
    await db.insert(
      'events',
      {
        'id': event.hashCode.toString(),
        'title': event.title,
        'notes': event.notes,
        'startTime': event.startTime.toIso8601String(),
        'endTime': event.endTime.toIso8601String(),
        'reminderMinutes': event.reminderMinutes.join(','),
        'color': event.color,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CalendarEvent>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) {
      return CalendarEvent(
        title: maps[i]['title'],
        notes: maps[i]['notes'],
        startTime: DateTime.parse(maps[i]['startTime']),
        endTime: DateTime.parse(maps[i]['endTime']),
        reminderMinutes: maps[i]['reminderMinutes']
            .split(',')
            .map<int>((e) => int.parse(e))
            .toList(),
        color: maps[i]['color'],
      );
    });
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    final db = await database;
    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [event.hashCode.toString()],
    );
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await deleteEvent(event);
    await insertEvent(event);
  }

  Future<DateTime?> getActiveFirstWeekDate() async {
    final db = await database;
    final result = await db.query(
      'semester_settings',
      where: 'is_active = 1',
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return DateTime.parse(result.first['first_week_date'] as String);
  }

  Future<void> setFirstWeekDate(DateTime date) async {
    final db = await database;
    await db.transaction((txn) async {
      // 将所有记录设置为非活动
      await txn.update('semester_settings', 
        {'is_active': 0},
        where: 'is_active = 1'
      );
      
      // 添加新的学期设置
      await txn.insert('semester_settings', {
        'first_week_date': date.toIso8601String(),
        'is_active': 1,
      });
    });
  }
}