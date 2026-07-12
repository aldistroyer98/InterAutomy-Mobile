import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interautomy_mobile/app/app.dart';

void main() {
  testWidgets('la aplicación inicia con Material 3', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: InterAutomyApp()));

    expect(find.byType(InterAutomyApp), findsOneWidget);
  });
}
