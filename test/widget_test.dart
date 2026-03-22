import 'package:flutter_test/flutter_test.dart';

import 'package:study_memory_app/app.dart';

void main() {
  testWidgets('StudyMemory renders core review sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudyMemoryApp());

    expect(find.text('SMemory'), findsOneWidget);
    expect(find.text('今日复习概览'), findsOneWidget);
    expect(find.text('逾期任务'), findsOneWidget);
    expect(find.text('添加'), findsOneWidget);
  });
}
