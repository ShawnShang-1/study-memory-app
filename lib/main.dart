import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/study_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StudyController.instance.initialize();
  runApp(const StudyMemoryApp());
}
