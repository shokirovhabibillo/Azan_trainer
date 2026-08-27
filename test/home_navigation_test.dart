import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:azon_trainer/main.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    await tester.pumpWidget(const AzonTrainerApp());
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Home ekranida "Bomdod azoni" alohida karta sifatida yo\'q',
      (tester) async {
    await pumpHome(tester);
    expect(find.text('Bomdod azoni'), findsNothing);
  });

  testWidgets(
      '"Azon" bosilganda 5 ta namoz vaqti ko\'rinadi (Bomdod bilan)',
      (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Azon'));
    await tester.pumpAndSettle();

    expect(find.text('Bomdod'), findsOneWidget);
    expect(find.text('Peshin'), findsOneWidget);
    expect(find.text('Asr'), findsOneWidget);
    expect(find.text('Shom'), findsOneWidget);
    expect(find.text('Xufton'), findsOneWidget);
  });

  testWidgets(
      '"Iqomat" bosilganda maqom tanlashsiz to\'g\'ridan-to\'g\'ri '
      'mashqqa o\'tadi', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Iqomat'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1/8'), findsOneWidget);
    expect(
      find.text('Mashq qilishdan oldin maqomni tanlang.'),
      findsNothing,
    );
  });

  testWidgets('"Azon duosi" bosilganda duo matni ko\'rinadi', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Azon duosi'));
    await tester.pumpAndSettle();

    expect(find.text('Ma\'nosi'), findsOneWidget);
  });
}
