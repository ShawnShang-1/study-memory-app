import 'package:flutter/foundation.dart';

enum ReviewTaskStatus { pending, completed }

enum MemoryLevel {
  forgot(1, '1 完全不会', 1),
  vague(2, '2 有点印象', 3),
  good(3, '3 基本掌握', 7),
  mastered(4, '4 熟练', 30);

  const MemoryLevel(this.score, this.label, this.nextIntervalDays);

  final int score;
  final String label;
  final int nextIntervalDays;
}

@immutable
class UserGoal {
  const UserGoal({required this.text, required this.updatedAt});

  final String text;
  final DateTime updatedAt;

  UserGoal copyWith({String? text, DateTime? updatedAt}) {
    return UserGoal(
      text: text ?? this.text,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class KnowledgeItem {
  const KnowledgeItem({
    required this.id,
    required this.title,
    required this.note,
    required this.subject,
    required this.createdAt,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.activeIntervalDays,
  });

  final int id;
  final String title;
  final String note;
  final String subject;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final int? activeIntervalDays;

  KnowledgeItem copyWith({
    String? title,
    String? note,
    String? subject,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    int? activeIntervalDays,
  }) {
    return KnowledgeItem(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      activeIntervalDays: activeIntervalDays ?? this.activeIntervalDays,
    );
  }
}

@immutable
class ReviewSchedule {
  const ReviewSchedule({
    required this.id,
    required this.knowledgeId,
    required this.dueAt,
    required this.intervalDays,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  final int id;
  final int knowledgeId;
  final DateTime dueAt;
  final int intervalDays;
  final ReviewTaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isPending => status == ReviewTaskStatus.pending;

  ReviewSchedule copyWith({
    DateTime? dueAt,
    int? intervalDays,
    ReviewTaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ReviewSchedule(
      id: id,
      knowledgeId: knowledgeId,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

@immutable
class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.knowledgeId,
    required this.scheduleId,
    required this.level,
    required this.reviewedAt,
    required this.nextReviewAt,
    required this.nextIntervalDays,
  });

  final int id;
  final int knowledgeId;
  final int scheduleId;
  final MemoryLevel level;
  final DateTime reviewedAt;
  final DateTime nextReviewAt;
  final int nextIntervalDays;
}

@immutable
class UserStats {
  const UserStats({
    required this.totalKnowledgeCount,
    required this.totalCompletedReviews,
    required this.todayReviewCount,
    required this.overdueCount,
    required this.upcomingCount,
    required this.totalXp,
    required this.currentLevel,
    required this.xpInCurrentLevel,
    required this.xpPerLevel,
    required this.levelProgress,
    required this.streakDays,
    required this.todayCompletedTasks,
    required this.allDueTasksCompleted,
  });

  final int totalKnowledgeCount;
  final int totalCompletedReviews;
  final int todayReviewCount;
  final int overdueCount;
  final int upcomingCount;
  final int totalXp;
  final int currentLevel;
  final int xpInCurrentLevel;
  final int xpPerLevel;
  final double levelProgress;
  final int streakDays;
  final int todayCompletedTasks;
  final bool allDueTasksCompleted;

  int get xpToNextLevel => xpPerLevel - xpInCurrentLevel;
}

@immutable
class ReviewTaskItem {
  const ReviewTaskItem({
    required this.knowledge,
    required this.schedule,
    required this.isOverdue,
  });

  final KnowledgeItem knowledge;
  final ReviewSchedule schedule;
  final bool isOverdue;
}
