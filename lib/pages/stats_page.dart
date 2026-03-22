import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../services/study_service.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_badge.dart';

class StatsPage extends StatelessWidget {
  StatsPage({super.key});

  final StudyController _controller = StudyController.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final UserStats stats = _controller.stats;
        final Color primary = Theme.of(context).colorScheme.primary;
        final Color secondary = Theme.of(context).colorScheme.secondary;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            _LevelHero(stats: stats, primary: primary, secondary: secondary),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double tileWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    SizedBox(
                      width: tileWidth,
                      child: StatBadge(
                        label: '连续学习',
                        value: '${stats.streakDays} 天',
                        color: primary,
                        icon: Icons.local_fire_department_rounded,
                        helper: '每天至少完成 1 个复习任务。',
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: StatBadge(
                        label: '今日完成',
                        value: '${stats.todayCompletedTasks} 项',
                        color: secondary,
                        icon: Icons.check_circle_rounded,
                        helper: '完成一次复习 +10 经验。',
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: StatBadge(
                        label: '总知识点',
                        value: '${stats.totalKnowledgeCount}',
                        color: const Color(0xFFE67E22),
                        icon: Icons.auto_stories_rounded,
                        helper: '新增知识点 +5 经验。',
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: StatBadge(
                        label: '全清奖励',
                        value: stats.allDueTasksCompleted ? '+30 经验' : '未完成',
                        color: const Color(0xFF2D9CDB),
                        icon: Icons.workspace_premium_rounded,
                        helper: '当天清空所有到期任务 +30 经验。',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.bolt_rounded, color: primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '经验规则',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _RuleRow(title: '新增知识点', reward: '+5 经验'),
                  const SizedBox(height: 10),
                  const _RuleRow(title: '完成一次复习', reward: '+10 经验'),
                  const SizedBox(height: 10),
                  const _RuleRow(title: '完成全部到期任务', reward: '+30 经验'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '复习概览',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OverviewRow(
                    label: '今日待复习',
                    value: '${stats.todayReviewCount}',
                  ),
                  _OverviewRow(label: '逾期任务', value: '${stats.overdueCount}'),
                  _OverviewRow(label: '未来计划', value: '${stats.upcomingCount}'),
                  _OverviewRow(
                    label: '累计完成复习',
                    value: '${stats.totalCompletedReviews}',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({
    required this.stats,
    required this.primary,
    required this.secondary,
  });

  final UserStats stats;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '当前等级',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '等级 ${stats.currentLevel}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '总经验',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalXp} 经验',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            '经验值进度',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stats.levelProgress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.26),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '本级经验 ${stats.xpInCurrentLevel}/${stats.xpPerLevel}，距离等级 ${stats.currentLevel + 1} 还差 ${stats.xpToNextLevel} 经验',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.title, required this.reward});

  final String title;
  final String reward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2FBF6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            reward,
            style: const TextStyle(
              color: Color(0xFF219653),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF4B5563)),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
