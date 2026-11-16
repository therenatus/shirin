import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves every screenshot the integration test takes into ./screenshots.
Future<void> main() async {
  final dir = Platform.environment['SHIRIN_SHOTS'] ?? 'screenshots';
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('$dir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
