import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/study_models.dart';

class AppDatabaseSnapshot {
  const AppDatabaseSnapshot({
    required this.goal,
    required this.knowledgeItems,
    required this.reviewSchedules,
    required this.reviewRecords,
    required this.totalXp,
    required this.streakDays,
    required this.todayCompletedTasks,
    required this.lastStudyDate,
    required this.dailyCounterDate,
    required this.allTasksBonusDate,
  });

  final UserGoal? goal;
  final List<KnowledgeItem> knowledgeItems;
  final List<ReviewSchedule> reviewSchedules;
  final List<ReviewRecord> reviewRecords;
  final int totalXp;
  final int streakDays;
  final int todayCompletedTasks;
  final DateTime? lastStudyDate;
  final DateTime? dailyCounterDate;
  final DateTime? allTasksBonusDate;
}

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String databaseName = 'study_memory.db';
  static const int databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final String databasesPath = await getDatabasesPath();
    final String path = p.join(databasesPath, databaseName);
    _database = await openDatabase(
      path,
      version: databaseVersion,
      onCreate: (Database db, int version) async {
        await _createTables(db);
      },
    );
    return _database!;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE user_goal (
        id INTEGER PRIMARY KEY,
        goal_text TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE knowledge (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT NOT NULL,
        subject TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_reviewed_at TEXT,
        next_review_at TEXT,
        active_interval_days INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE review_schedule (
        id INTEGER PRIMARY KEY,
        knowledge_id INTEGER NOT NULL,
        due_at TEXT NOT NULL,
        interval_days INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (knowledge_id) REFERENCES knowledge(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE review_record (
        id INTEGER PRIMARY KEY,
        knowledge_id INTEGER NOT NULL,
        schedule_id INTEGER NOT NULL,
        memory_level INTEGER NOT NULL,
        reviewed_at TEXT NOT NULL,
        next_review_at TEXT NOT NULL,
        next_interval_days INTEGER NOT NULL,
        FOREIGN KEY (knowledge_id) REFERENCES knowledge(id),
        FOREIGN KEY (schedule_id) REFERENCES review_schedule(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY,
        total_xp INTEGER NOT NULL,
        streak_days INTEGER NOT NULL,
        today_completed_tasks INTEGER NOT NULL,
        last_study_date TEXT,
        daily_counter_date TEXT,
        all_tasks_bonus_date TEXT
      )
    ''');
  }

  Future<AppDatabaseSnapshot> loadSnapshot() async {
    final Database db = await database;

    final List<Map<String, Object?>> goalRows = await db.query(
      'user_goal',
      limit: 1,
    );
    final List<Map<String, Object?>> knowledgeRows = await db.query(
      'knowledge',
    );
    final List<Map<String, Object?>> scheduleRows = await db.query(
      'review_schedule',
    );
    final List<Map<String, Object?>> recordRows = await db.query(
      'review_record',
    );
    final List<Map<String, Object?>> statsRows = await db.query(
      'user_stats',
      limit: 1,
    );

    final UserGoal? goal = goalRows.isEmpty
        ? null
        : UserGoal(
            text: goalRows.first['goal_text']! as String,
            updatedAt: DateTime.parse(goalRows.first['updated_at']! as String),
          );

    final List<KnowledgeItem> knowledgeItems = knowledgeRows.map((
      Map<String, Object?> row,
    ) {
      return KnowledgeItem(
        id: row['id']! as int,
        title: row['title']! as String,
        note: row['note']! as String,
        subject: row['subject']! as String,
        createdAt: DateTime.parse(row['created_at']! as String),
        lastReviewedAt: _parseNullableDate(row['last_reviewed_at']),
        nextReviewAt: _parseNullableDate(row['next_review_at']),
        activeIntervalDays: row['active_interval_days'] as int?,
      );
    }).toList();

    final List<ReviewSchedule> reviewSchedules = scheduleRows.map((
      Map<String, Object?> row,
    ) {
      return ReviewSchedule(
        id: row['id']! as int,
        knowledgeId: row['knowledge_id']! as int,
        dueAt: DateTime.parse(row['due_at']! as String),
        intervalDays: row['interval_days']! as int,
        status: (row['status']! as String) == 'completed'
            ? ReviewTaskStatus.completed
            : ReviewTaskStatus.pending,
        createdAt: DateTime.parse(row['created_at']! as String),
        completedAt: _parseNullableDate(row['completed_at']),
      );
    }).toList();

    final List<ReviewRecord> reviewRecords = recordRows.map((
      Map<String, Object?> row,
    ) {
      final int score = row['memory_level']! as int;
      return ReviewRecord(
        id: row['id']! as int,
        knowledgeId: row['knowledge_id']! as int,
        scheduleId: row['schedule_id']! as int,
        level: MemoryLevel.values.firstWhere(
          (MemoryLevel level) => level.score == score,
        ),
        reviewedAt: DateTime.parse(row['reviewed_at']! as String),
        nextReviewAt: DateTime.parse(row['next_review_at']! as String),
        nextIntervalDays: row['next_interval_days']! as int,
      );
    }).toList();

    final Map<String, Object?>? stats = statsRows.isEmpty
        ? null
        : statsRows.first;

    return AppDatabaseSnapshot(
      goal: goal,
      knowledgeItems: knowledgeItems,
      reviewSchedules: reviewSchedules,
      reviewRecords: reviewRecords,
      totalXp: (stats?['total_xp'] as int?) ?? 0,
      streakDays: (stats?['streak_days'] as int?) ?? 0,
      todayCompletedTasks: (stats?['today_completed_tasks'] as int?) ?? 0,
      lastStudyDate: _parseNullableDate(stats?['last_study_date']),
      dailyCounterDate: _parseNullableDate(stats?['daily_counter_date']),
      allTasksBonusDate: _parseNullableDate(stats?['all_tasks_bonus_date']),
    );
  }

  Future<void> saveSnapshot({
    required UserGoal goal,
    required List<KnowledgeItem> knowledgeItems,
    required List<ReviewSchedule> reviewSchedules,
    required List<ReviewRecord> reviewRecords,
    required int totalXp,
    required int streakDays,
    required int todayCompletedTasks,
    required DateTime? lastStudyDate,
    required DateTime? dailyCounterDate,
    required DateTime? allTasksBonusDate,
  }) async {
    final Database db = await database;

    await db.transaction((Transaction txn) async {
      await txn.delete('user_goal');
      await txn.delete('knowledge');
      await txn.delete('review_schedule');
      await txn.delete('review_record');
      await txn.delete('user_stats');

      await txn.insert('user_goal', <String, Object?>{
        'id': 1,
        'goal_text': goal.text,
        'updated_at': goal.updatedAt.toIso8601String(),
      });

      for (final KnowledgeItem item in knowledgeItems) {
        await txn.insert('knowledge', <String, Object?>{
          'id': item.id,
          'title': item.title,
          'note': item.note,
          'subject': item.subject,
          'created_at': item.createdAt.toIso8601String(),
          'last_reviewed_at': item.lastReviewedAt?.toIso8601String(),
          'next_review_at': item.nextReviewAt?.toIso8601String(),
          'active_interval_days': item.activeIntervalDays,
        });
      }

      for (final ReviewSchedule schedule in reviewSchedules) {
        await txn.insert('review_schedule', <String, Object?>{
          'id': schedule.id,
          'knowledge_id': schedule.knowledgeId,
          'due_at': schedule.dueAt.toIso8601String(),
          'interval_days': schedule.intervalDays,
          'status': schedule.status.name,
          'created_at': schedule.createdAt.toIso8601String(),
          'completed_at': schedule.completedAt?.toIso8601String(),
        });
      }

      for (final ReviewRecord record in reviewRecords) {
        await txn.insert('review_record', <String, Object?>{
          'id': record.id,
          'knowledge_id': record.knowledgeId,
          'schedule_id': record.scheduleId,
          'memory_level': record.level.score,
          'reviewed_at': record.reviewedAt.toIso8601String(),
          'next_review_at': record.nextReviewAt.toIso8601String(),
          'next_interval_days': record.nextIntervalDays,
        });
      }

      await txn.insert('user_stats', <String, Object?>{
        'id': 1,
        'total_xp': totalXp,
        'streak_days': streakDays,
        'today_completed_tasks': todayCompletedTasks,
        'last_study_date': lastStudyDate?.toIso8601String(),
        'daily_counter_date': dailyCounterDate?.toIso8601String(),
        'all_tasks_bonus_date': allTasksBonusDate?.toIso8601String(),
      });
    });
  }

  DateTime? _parseNullableDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String);
  }
}
