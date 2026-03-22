import 'package:flutter/material.dart';

import '../services/study_service.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key, this.initialGoal});

  final String? initialGoal;

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final StudyController _controller = StudyController.instance;
  late final TextEditingController _textController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.initialGoal ?? _controller.goal.text,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目标设置')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '设置你的考研目标，方便你长期保持学习方向。',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '考研目标',
                hintText: '例如：考上北京大学计算机研究生',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveGoal,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存目标'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGoal() async {
    setState(() {
      _isSaving = true;
    });

    await _controller.updateGoal(_textController.text);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }
}
