import 'package:flutter_test/flutter_test.dart';
import 'package:shirin_app/app.dart';
import 'package:shirin_app/core/di/injection_container.dart' as di;

void main() {
  setUpAll(() async {
    await di.init();
  });

  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ShirinApp());
    await tester.pump();
  });
}
