import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';
import 'calendar_sync_service.dart';

class EventRepository {
  static Database? _database;
  // 添加并初始化_syncService变量
  final CalendarSyncService _syncService = CalendarSyncService();
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calendar.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events(
            id TEXT PRIMARY KEY,
            title TEXT,
            notes TEXT,
            startTime TEXT,
            endTime TEXT,
            reminderMinutes TEXT,
            color TEXT,
            first_week_date TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 0,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
        CREATE TABLE semester_settings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          first_week_date TEXT NOT NULL,
          is_active INTEGER DEFAULT 0
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE settings(
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
          await db.execute(
            'ALTER TABLE events ADD COLUMN synced INTEGER DEFAULT 0',
          );
        }
      },
    );
  }

  Future<void> insertEvent(CalendarEvent event) async {
    final db = await database;
    
    final firstWeekDate = await getActiveFirstWeekDate();
    // 在本地数据库中插入事件
    await db.insert('events', {
      'id': event.id,
      'title': event.title,
      'notes': event.notes,
      'startTime': event.startTime.toIso8601String(),
      'endTime': event.endTime.toIso8601String(),
      'reminderMinutes': event.reminderMinutes.join(','),
      'color': event.color,
      'synced': 0,
      'first_week_date': firstWeekDate?.toIso8601String() ?? DateTime.now().toString(),
      'is_active': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // 如果启用了同步，则同步到系统日历
    if (_syncService.isSyncEnabled()) {
      final success = await _syncService.syncEventToSystem(event);
      if (success) {
        // 更新同步状态
        await db.update(
          'events',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [event.id],
        );
      }
    }
  }

  Future<List<CalendarEvent>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) {
      return CalendarEvent(
        id: maps[i]['id'],
        title: maps[i]['title'],
        notes: maps[i]['notes'],
        startTime: DateTime.parse(maps[i]['startTime']),
        endTime: DateTime.parse(maps[i]['endTime']),
        reminderMinutes:
            maps[i]['reminderMinutes']
                .split(',')
                .map<int>((e) => int.parse(e))
                .toList(),
        color: maps[i]['color'],
      );
    });
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    final db = await database;
    // 如果启用了同步，则从系统日历中删除
    if (_syncService.isSyncEnabled()) {
      await _syncService.deleteEventFromSystem(event);
    }
    await db.delete('events', where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await deleteEvent(event);
    await insertEvent(event);
  }

  Future<DateTime?> getActiveFirstWeekDate() async {
    final db = await database;
    try {
      final result = await db.query(
        'semester_settings',
        where: 'is_active = 1',
        limit: 1,
      );

      if (result.isEmpty) return null;
      return DateTime.parse(result.first['first_week_date'] as String);
    } catch (e) {
      // 表不存在或其他错误
      return null;
    }
  }

  Future<void> setFirstWeekDate(DateTime date) async {
    final db = await database;
    await db.transaction((txn) async {
      // 将所有记录设置为非活动
      await txn.update('semester_settings', {
        'is_active': 0,
      }, where: 'is_active = 1');

      // 添加新的学期设置
      await txn.insert('semester_settings', {
        'first_week_date': date.toIso8601String(),
        'is_active': 1,
      });
    });
  }

  // 同步所有未同步的事件到系统日历
  Future<int> syncAllUnsyncedEvents() async {
    if (!_syncService.isSyncEnabled()) {
      return 0;
    }
    
    final db = await database;
    final unsyncedEvents = await db.query(
      'events',
      where: 'synced = ?',
      whereArgs: [0],
    );
    
    final events = unsyncedEvents.map((map) => CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      reminderMinutes: (map['reminderMinutes'] as String)
          .split(',')
          .map<int>((e) => int.parse(e))
          .toList(),
      color: map['color'] as String,
    )).toList();
    
    int successCount = await _syncService.syncMultipleEvents(events);
    
    // 更新同步状态
    if (successCount > 0) {
      for (var event in events) {
        await db.update(
          'events',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [event.id],
        );
      }
    }
    
    return successCount;
  }

  Future<bool> isFirstLaunch() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['has_launched'],
    );

    if (maps.isEmpty) {
      // 如果没有这个键，说明是首次启动
      await db.insert('settings', {
        'key': 'has_launched',
        'value': 'true',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    }
    return false;
  }
}