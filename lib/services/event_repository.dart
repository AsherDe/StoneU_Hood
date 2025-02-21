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
      version: 1,
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
      },
    );
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
}