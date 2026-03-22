import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../services/study_service.dart';
import '../widgets/section_card.dart';

class CalendarPage extends StatelessWidget {
  CalendarPage({super.key});

  final StudyController _controller = StudyController.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final List<ReviewTaskItem> upcomingTasks = _controller.upcomingTasks;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              '后续复习计划',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '这里展示今天之后的待复习任务安排。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            if (upcomingTasks.isEmpty)
              const SectionCard(child: Text('目前还没有后续计划，添加知识点后会自动生成。'))
            else
              ...upcomingTasks.map(
                (ReviewTaskItem item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _controller.formatAbsoluteDate(item.schedule.dueAt),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.knowledge.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(item.knowledge.subject),
                              const SizedBox(height: 4),
                              Text('间隔：${item.schedule.intervalDays} 天'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
