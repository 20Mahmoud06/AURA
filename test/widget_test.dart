import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    // Basic sanity check: the app tree builds.
    expect(find.byType(App), findsOneWidget);
  });
}
