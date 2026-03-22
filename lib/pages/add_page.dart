import 'package:flutter/material.dart';

import '../services/study_service.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final StudyController _controller = StudyController.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedSubject = '数学';
  bool _isSaving = false;

  final List<String> _subjects = <String>['数学', '英语', '政治', '专业课'];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加知识点')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '每新增一个知识点，系统都会自动生成后续复习计划。',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '知识点标题',
                hintText: '例如：函数极限未定式',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration(labelText: '科目'),
              items: _subjects
                  .map(
                    (String subject) => DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedSubject = value;
                        });
                      }
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '记录公式、例题或记忆提示',
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '初始复习计划',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('${_controller.initialIntervals.join(' / ')} 天'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveKnowledge,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存知识点'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveKnowledge() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入知识点标题。')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await _controller.addKnowledge(
      title: title,
      note: _noteController.text,
      subject: _selectedSubject,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('知识点已添加，复习计划已生成。')));
  }
}
