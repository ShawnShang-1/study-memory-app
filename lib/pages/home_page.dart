import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../services/study_service.dart';
import '../widgets/section_card.dart';
import 'add_page.dart';
import 'calendar_page.dart';
import 'goal_page.dart';
import 'stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StudyController _controller = StudyController.instance;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final List<Widget> tabs = <Widget>[
          _DashboardTab(controller: _controller),
          CalendarPage(),
          StatsPage(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('SMemory'),
            actions: <Widget>[
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          GoalPage(initialGoal: _controller.goal.text),
                    ),
                  );
                },
                icon: const Icon(Icons.flag_outlined),
                tooltip: '编辑目标',
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(index: _currentIndex, children: tabs),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const AddPage()));
            },
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '今天',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: '计划',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: '统计',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.controller});

  final StudyController controller;

  @override
  Widget build(BuildContext context) {
    final UserStats stats = controller.stats;
    final List<ReviewTaskItem> overdueTasks = controller.overdueTasks;
    final List<ReviewTaskItem> todayTasks = controller.todayTasks;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: <Widget>[
        _HeroCard(stats: stats),
        const SizedBox(height: 20),
        _TaskSection(
          title: '逾期任务',
          subtitle: '建议先处理逾期内容，避免复习节奏继续延后。',
          emptyLabel: '当前没有逾期任务。',
          accentColor: const Color(0xFFEB5757),
          tasks: overdueTasks,
          controller: controller,
        ),
        const SizedBox(height: 20),
        _TaskSection(
          title: '今日复习',
          subtitle: '下面是今天需要完成的复习任务。',
          emptyLabel: '今天暂时没有待复习任务，可以先去添加知识点。',
          accentColor: Theme.of(context).colorScheme.primary,
          tasks: todayTasks,
          controller: controller,
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            primary.withValues(alpha: 0.96),
            secondary.withValues(alpha: 0.96),
          ],
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
          Text(
            '今天',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '今日复习概览',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '把注意力放在今天需要完成的任务上，目标可在右上角单独编辑。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _GlassChip(
                icon: Icons.stars_rounded,
                label: '等级 ${stats.currentLevel}  ${stats.totalXp} 经验',
              ),
              _GlassChip(
                icon: Icons.local_fire_department_rounded,
                label: '连续 ${stats.streakDays} 天',
              ),
              _GlassChip(
                icon: Icons.check_circle_rounded,
                label: '今日完成 ${stats.todayCompletedTasks} 项',
              ),
              _GlassChip(
                icon: Icons.today_outlined,
                label: '待复习 ${stats.todayReviewCount} 项',
              ),
              _GlassChip(
                icon: Icons.warning_amber_rounded,
                label: '逾期 ${stats.overdueCount} 项',
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stats.levelProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '距离下一级还差 ${stats.xpToNextLevel} 经验值',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.subtitle,
    required this.emptyLabel,
    required this.accentColor,
    required this.tasks,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final String emptyLabel;
  final Color accentColor;
  final List<ReviewTaskItem> tasks;
  final StudyController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          SectionCard(child: Text(emptyLabel))
        else
          ...tasks.map(
            (ReviewTaskItem task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TaskCard(
                item: task,
                accentColor: accentColor,
                onComplete: () => _showReviewSheet(context, task),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showReviewSheet(
    BuildContext context,
    ReviewTaskItem item,
  ) async {
    final MemoryLevel? level = await showModalBottomSheet<MemoryLevel>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF9FBFC),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.knowledge.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text('请根据复习结果选择你的记忆程度。'),
                const SizedBox(height: 16),
                ...MemoryLevel.values.map(
                  (MemoryLevel option) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: Text(option.label),
                      subtitle: Text('下次复习：${option.nextIntervalDays}天后'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).pop(option),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (level == null) {
      return;
    }

    await controller.completeTask(scheduleId: item.schedule.id, level: level);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.knowledge.title} 已完成复习，${controller.describeReviewRule(level)}。',
          ),
        ),
      );
    }
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.item,
    required this.accentColor,
    required this.onComplete,
  });

  final ReviewTaskItem item;
  final Color accentColor;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final StudyController controller = StudyController.instance;

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 10,
            height: 90,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.knowledge.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.knowledge.subject,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                if (item.knowledge.note.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    item.knowledge.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _PillLabel(
                      text: controller.formatDueLabel(item),
                      color: accentColor,
                    ),
                    _PillLabel(
                      text: '间隔 ${item.schedule.intervalDays} 天',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    FilledButton.tonal(
                      onPressed: onComplete,
                      child: const Text('去复习'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
