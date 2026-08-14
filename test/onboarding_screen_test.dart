import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:azon_trainer/screens/app_startup_gate.dart';
import 'package:azon_trainer/screens/onboarding_screen.dart';
import 'package:azon_trainer/services/onboarding_service.dart';

void main() {
  group('AppStartupGate', () {
    testWidgets('yangi o\'rnatishda (fresh install) onboarding chiqadi',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(home: AppStartupGate()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Azon Trainer\'ga xush kelibsiz'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
    });

    testWidgets(
        'onboarding avval tugallangan bo\'lsa, Home ekrani darhol '
        'ko\'rinadi', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});

      await tester.pumpWidget(
        const MaterialApp(home: AppStartupGate()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Azon Trainer'), findsOneWidget);
      expect(find.text('Azon Trainer\'ga xush kelibsiz'), findsNothing);
    });
  });

  group('OnboardingScreen — majburiy o\'qish cheklovi', () {
    testWidgets(
        '1-sahifada "Davom etish" boshida o\'chirilgan (disabled)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'minimal o\'qish vaqti va pastgacha scroll qilingandan keyin '
        '"Davom etish" yoqiladi', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pump();

      // Pastgacha scroll qilamiz (talab: "pastgacha yetib borish" sharti).
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
        500,
      );
      await tester.pumpAndSettle();

      // Minimal o'qish vaqtini "kutamiz" — virtual soat orqali, real
      // vaqt sarflamasdan (flutter_test FakeAsync orqali).
      await tester.pump(const Duration(seconds: 60));

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('"Skip" yoki "Later" tugmasi mavjud emas', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pump();

      expect(find.text('Skip'), findsNothing);
      expect(find.text('Later'), findsNothing);
      expect(find.text('O\'tkazib yuborish'), findsNothing);
    });

    testWidgets(
        'yakuniy sahifada checkbox belgilanmasa "boshlash" tugmasi '
        'o\'chirilgan', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService();
      expect(await service.isCompleted(), isFalse);

      // To'rtta sahifani "o'tib", yakuniy tasdiqlash sahifasiga
      // yetamiz — har birida vaqt/scroll shartini bajarib.
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );

      for (int i = 0; i < 4; i++) {
        await tester.pump();
        await tester.fling(
          find.byType(SingleChildScrollView),
          const Offset(0, -600),
          800,
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 60));
        await tester.tap(find.widgetWithText(ElevatedButton, 'Davom etish'));
        await tester.pump();
      }

      // Endi yakuniy tasdiqlash sahifasidamiz.
      expect(
        find.text(
          'Men yuqoridagi ma\'lumotlarni to\'liq o\'qib '
          'chiqdim va tushundim.',
        ),
        findsOneWidget,
      );

      final startButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Azon Trainer\'dan boshlash'),
      );
      expect(startButton.onPressed, isNull);

      // Checkbox belgilaymiz.
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final startButtonAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Azon Trainer\'dan boshlash'),
      );
      expect(startButtonAfter.onPressed, isNotNull);
    });
  });

  group('OnboardingScreen — ko\'rib chiqish rejimi (isReviewMode)', () {
    testWidgets(
        'review rejimida hech qanday cheklov yo\'q, darhol '
        '"Davom etish" yoqilgan', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(isReviewMode: true),
        ),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
