import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/study_models.dart';

class StudyController extends ChangeNotifier {
  StudyController._();

  static final StudyController instance = StudyController._();

  final AppDatabase _database = AppDatabase.instance;
  final List<int> _initialIntervals = <int>[1, 3, 7, 15, 30];
  final List<KnowledgeItem> _knowledgeItems = <KnowledgeItem>[];
  final List<ReviewSchedule> _reviewSchedules = <ReviewSchedule>[];
  final List<ReviewRecord> _reviewRecords = <ReviewRecord>[];
  final int _xpPerLevel = 100;

  UserGoal _goal = UserGoal(text: '写下你的考研目标', updatedAt: DateTime.now());

  int _nextKnowledgeId = 1;
  int _nextScheduleId = 1;
  int _nextRecordId = 1;
  int _totalXp = 0;
  int _streakDays = 0;
  int _todayCompletedTasks = 0;
  DateTime? _lastStudyDate;
  DateTime? _dailyCounterDate;
  DateTime? _allTasksBonusDate;
  bool _initialized = false;

  UserGoal get goal => _goal;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final AppDatabaseSnapshot snapshot = await _database.loadSnapshot();

    if (snapshot.goal != null) {
      _goal = _normalizeGoal(snapshot.goal!);
    }

    _knowledgeItems
      ..clear()
      ..addAll(snapshot.knowledgeItems.map(_normalizeKnowledgeItem));
    _reviewSchedules
      ..clear()
      ..addAll(snapshot.reviewSchedules);
    _reviewRecords
      ..clear()
      ..addAll(snapshot.reviewRecords);

    _totalXp = snapshot.totalXp;
    _streakDays = snapshot.streakDays;
    _todayCompletedTasks = snapshot.todayCompletedTasks;
    _lastStudyDate = snapshot.lastStudyDate;
    _dailyCounterDate = snapshot.dailyCounterDate;
    _allTasksBonusDate = snapshot.allTasksBonusDate;

    _nextKnowledgeId = _nextId(
      _knowledgeItems.map((KnowledgeItem item) => item.id),
    );
    _nextScheduleId = _nextId(
      _reviewSchedules.map((ReviewSchedule item) => item.id),
    );
    _nextRecordId = _nextId(_reviewRecords.map((ReviewRecord item) => item.id));

    _syncDailyCounters(DateTime.now());
    _initialized = true;
    await _persist();
    notifyListeners();
  }

  UnmodifiableListView<int> get initialIntervals =>
      UnmodifiableListView<int>(_initialIntervals);

  UnmodifiableListView<ReviewTaskItem> get todayTasks =>
      UnmodifiableListView<ReviewTaskItem>(
        _buildTaskItems(_todayPendingSchedules),
      );

  UnmodifiableListView<ReviewTaskItem> get overdueTasks =>
      UnmodifiableListView<ReviewTaskItem>(
        _buildTaskItems(_overduePendingSchedules),
      );

  UnmodifiableListView<ReviewTaskItem> get upcomingTasks =>
      UnmodifiableListView<ReviewTaskItem>(
        _buildTaskItems(_upcomingPendingSchedules),
      );

  UnmodifiableListView<KnowledgeItem> get knowledgeItems =>
      UnmodifiableListView<KnowledgeItem>(
        _knowledgeItems.toList()..sort(
          (KnowledgeItem a, KnowledgeItem b) =>
              b.createdAt.compareTo(a.createdAt),
        ),
      );

  UnmodifiableListView<ReviewRecord> get reviewRecords =>
      UnmodifiableListView<ReviewRecord>(
        _reviewRecords.toList()..sort(
          (ReviewRecord a, ReviewRecord b) =>
              b.reviewedAt.compareTo(a.reviewedAt),
        ),
      );

  UserStats get stats {
    _syncDailyCounters(DateTime.now());

    final int xpInCurrentLevel = _totalXp % _xpPerLevel;
    final double levelProgress = xpInCurrentLevel / _xpPerLevel;

    return UserStats(
      totalKnowledgeCount: _knowledgeItems.length,
      totalCompletedReviews: _reviewRecords.length,
      todayReviewCount: _todayPendingSchedules.length,
      overdueCount: _overduePendingSchedules.length,
      upcomingCount: _upcomingPendingSchedules.length,
      totalXp: _totalXp,
      currentLevel: (_totalXp ~/ _xpPerLevel) + 1,
      xpInCurrentLevel: xpInCurrentLevel,
      xpPerLevel: _xpPerLevel,
      levelProgress: levelProgress,
      streakDays: _streakDays,
      todayCompletedTasks: _todayCompletedTasks,
      allDueTasksCompleted:
          _dueNowPendingSchedules.isEmpty && _todayCompletedTasks > 0,
    );
  }

  Future<void> updateGoal(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _goal = _goal.copyWith(text: trimmed, updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  Future<void> addKnowledge({
    required String title,
    required String note,
    required String subject,
  }) async {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    _syncDailyCounters(now);

    final KnowledgeItem item = KnowledgeItem(
      id: _nextKnowledgeId++,
      title: trimmedTitle,
      note: note.trim(),
      subject: subject.trim().isEmpty ? '通用' : subject.trim(),
      createdAt: now,
      nextReviewAt: _normalizedDueDate(now, _initialIntervals.first),
      activeIntervalDays: _initialIntervals.first,
    );

    _knowledgeItems.add(item);
    for (final int interval in _initialIntervals) {
      _reviewSchedules.add(
        ReviewSchedule(
          id: _nextScheduleId++,
          knowledgeId: item.id,
          dueAt: _normalizedDueDate(now, interval),
          intervalDays: interval,
          status: ReviewTaskStatus.pending,
          createdAt: now,
        ),
      );
    }

    _awardXp(5);
    notifyListeners();
    await _persist();
  }

  Future<void> completeTask({
    required int scheduleId,
    required MemoryLevel level,
  }) async {
    final int scheduleIndex = _reviewSchedules.indexWhere(
      (ReviewSchedule schedule) =>
          schedule.id == scheduleId && schedule.isPending,
    );
    if (scheduleIndex == -1) {
      return;
    }

    final ReviewSchedule currentSchedule = _reviewSchedules[scheduleIndex];
    final int knowledgeIndex = _knowledgeItems.indexWhere(
      (KnowledgeItem item) => item.id == currentSchedule.knowledgeId,
    );
    if (knowledgeIndex == -1) {
      return;
    }

    final DateTime now = DateTime.now();
    _syncDailyCounters(now);

    final int nextIntervalDays = level.nextIntervalDays;
    final DateTime nextReviewAt = _normalizedDueDate(now, nextIntervalDays);

    _reviewSchedules[scheduleIndex] = currentSchedule.copyWith(
      status: ReviewTaskStatus.completed,
      completedAt: now,
    );

    _reviewSchedules.removeWhere(
      (ReviewSchedule schedule) =>
          schedule.knowledgeId == currentSchedule.knowledgeId &&
          schedule.id != currentSchedule.id &&
          schedule.isPending,
    );

    _reviewSchedules.add(
      ReviewSchedule(
        id: _nextScheduleId++,
        knowledgeId: currentSchedule.knowledgeId,
        dueAt: nextReviewAt,
        intervalDays: nextIntervalDays,
        status: ReviewTaskStatus.pending,
        createdAt: now,
      ),
    );

    _reviewRecords.add(
      ReviewRecord(
        id: _nextRecordId++,
        knowledgeId: currentSchedule.knowledgeId,
        scheduleId: currentSchedule.id,
        level: level,
        reviewedAt: now,
        nextReviewAt: nextReviewAt,
        nextIntervalDays: nextIntervalDays,
      ),
    );

    final KnowledgeItem currentKnowledge = _knowledgeItems[knowledgeIndex];
    _knowledgeItems[knowledgeIndex] = currentKnowledge.copyWith(
      lastReviewedAt: now,
      nextReviewAt: nextReviewAt,
      activeIntervalDays: nextIntervalDays,
    );

    _recordStudyCompletion(now);
    _awardXp(10);

    if (_shouldAwardAllTasksBonus(now)) {
      _awardXp(30);
      _allTasksBonusDate = _startOfDay(now);
    }

    notifyListeners();
    await _persist();
  }

  KnowledgeItem? knowledgeFor(int knowledgeId) {
    for (final KnowledgeItem item in _knowledgeItems) {
      if (item.id == knowledgeId) {
        return item;
      }
    }
    return null;
  }

  String formatDueLabel(ReviewTaskItem item) {
    if (item.isOverdue) {
      final int overdueDays = _startOfDay(
        DateTime.now(),
      ).difference(_startOfDay(item.schedule.dueAt)).inDays;
      return overdueDays <= 1 ? '逾期 1 天' : '逾期 $overdueDays 天';
    }

    return '今天';
  }

  String formatAbsoluteDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  String describeReviewRule(MemoryLevel level) {
    return '${level.label}，下次复习：${level.nextIntervalDays}天后';
  }

  List<ReviewTaskItem> _buildTaskItems(List<ReviewSchedule> schedules) {
    final List<ReviewTaskItem> items = <ReviewTaskItem>[];
    for (final ReviewSchedule schedule in schedules) {
      final KnowledgeItem? knowledge = knowledgeFor(schedule.knowledgeId);
      if (knowledge != null) {
        items.add(
          ReviewTaskItem(
            knowledge: knowledge,
            schedule: schedule,
            isOverdue: _isOverdue(schedule),
          ),
        );
      }
    }
    return items;
  }

  List<ReviewSchedule> get _pendingSchedules {
    final List<ReviewSchedule> pending =
        _reviewSchedules
            .where((ReviewSchedule schedule) => schedule.isPending)
            .toList()
          ..sort(
            (ReviewSchedule a, ReviewSchedule b) => a.dueAt.compareTo(b.dueAt),
          );
    return pending;
  }

  List<ReviewSchedule> get _todayPendingSchedules => _pendingSchedules
      .where((ReviewSchedule schedule) => _isToday(schedule.dueAt))
      .toList();

  List<ReviewSchedule> get _overduePendingSchedules => _pendingSchedules
      .where((ReviewSchedule schedule) => _isOverdue(schedule))
      .toList();

  List<ReviewSchedule> get _upcomingPendingSchedules => _pendingSchedules
      .where(
        (ReviewSchedule schedule) =>
            !_isOverdue(schedule) && !_isToday(schedule.dueAt),
      )
      .toList();

  List<ReviewSchedule> get _dueNowPendingSchedules => _pendingSchedules
      .where(
        (ReviewSchedule schedule) =>
            _isOverdue(schedule) || _isToday(schedule.dueAt),
      )
      .toList();

  bool _isOverdue(ReviewSchedule schedule) {
    return _startOfDay(schedule.dueAt).isBefore(_startOfDay(DateTime.now()));
  }

  bool _isToday(DateTime date) {
    return DateUtils.isSameDay(date, DateTime.now());
  }

  DateTime _normalizedDueDate(DateTime base, int intervalDays) {
    return _startOfDay(base).add(Duration(days: intervalDays));
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _awardXp(int amount) {
    _totalXp += amount;
  }

  void _syncDailyCounters(DateTime now) {
    final DateTime day = _startOfDay(now);
    if (_dailyCounterDate == null ||
        !DateUtils.isSameDay(_dailyCounterDate, day)) {
      _dailyCounterDate = day;
      _todayCompletedTasks = 0;
      _allTasksBonusDate = null;
    }
  }

  void _recordStudyCompletion(DateTime now) {
    final DateTime today = _startOfDay(now);

    if (_todayCompletedTasks == 0) {
      if (_lastStudyDate == null) {
        _streakDays = 1;
      } else {
        final int difference = today
            .difference(_startOfDay(_lastStudyDate!))
            .inDays;
        if (difference <= 0) {
          _streakDays = _streakDays == 0 ? 1 : _streakDays;
        } else if (difference == 1) {
          _streakDays += 1;
        } else {
          _streakDays = 1;
        }
      }
    }

    _todayCompletedTasks += 1;
    _lastStudyDate = today;
  }

  bool _shouldAwardAllTasksBonus(DateTime now) {
    return _todayCompletedTasks > 0 &&
        _dueNowPendingSchedules.isEmpty &&
        (_allTasksBonusDate == null ||
            !DateUtils.isSameDay(_allTasksBonusDate, now));
  }

  int _nextId(Iterable<int> values) {
    int maxValue = 0;
    for (final int value in values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
    return maxValue + 1;
  }

  Future<void> _persist() async {
    if (!_initialized) {
      return;
    }

    await _database.saveSnapshot(
      goal: _goal,
      knowledgeItems: _knowledgeItems,
      reviewSchedules: _reviewSchedules,
      reviewRecords: _reviewRecords,
      totalXp: _totalXp,
      streakDays: _streakDays,
      todayCompletedTasks: _todayCompletedTasks,
      lastStudyDate: _lastStudyDate,
      dailyCounterDate: _dailyCounterDate,
      allTasksBonusDate: _allTasksBonusDate,
    );
  }

  UserGoal _normalizeGoal(UserGoal goal) {
    if (goal.text == 'Set your exam goal' ||
        goal.text == 'Get into PKU Computer Science') {
      return goal.copyWith(text: '写下你的考研目标');
    }
    return goal;
  }

  KnowledgeItem _normalizeKnowledgeItem(KnowledgeItem item) {
    return item.copyWith(
      title: _translateLegacyTitle(item.title),
      note: _translateLegacyNote(item.note),
      subject: _translateLegacySubject(item.subject),
    );
  }

  String _translateLegacySubject(String subject) {
    switch (subject) {
      case 'Math':
        return '数学';
      case 'English':
        return '英语';
      case 'Politics':
        return '政治';
      case 'Major':
        return '专业课';
      case 'General':
        return '通用';
      default:
        return subject;
    }
  }

  String _translateLegacyTitle(String title) {
    switch (title) {
      case 'Indeterminate forms of limits':
        return '函数极限未定式';
      case 'Long English sentence parsing':
        return '英语长难句分析';
      case 'Eigenvalues in linear algebra':
        return '线性代数特征值';
      default:
        return title;
    }
  }

  String _translateLegacyNote(String note) {
    switch (note) {
      case 'Review the common seven forms and one example for each.':
        return '复习常见的七种未定式，并为每种准备一个例题。';
      case 'Mark subject, predicate, clauses, and linking words.':
        return '标出主谓、从句结构和连接词。';
      default:
        return note;
    }
  }
}
