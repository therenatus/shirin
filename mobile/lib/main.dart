import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/push/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await di.sl<PushService>().init();
  runApp(const ShirinApp());
}
