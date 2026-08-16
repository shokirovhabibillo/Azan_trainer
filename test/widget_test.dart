import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:azon_trainer/main.dart';

/// Oddiy "smoke test" — ilova ishga tushganda Home ekrani va asosiy
/// navigatsiya elementlari ko'rinishini tekshiradi.
///
/// MUHIM: bu faylning mavjudligi `flutter create` buyrug'i CI'da
/// o'zining standart (va noto'g'ri paket nomiga ishora qiluvchi)
/// widget_test.dart shablonini yaratishining oldini oladi — `flutter
/// create` bu faylni faqat u mavjud bo'lmaganda generatsiya qiladi.
///
/// v1.13: ilova endi avval `AppStartupGate` orqali onboarding
/// holatini tekshiradi. Bu test Home ekranining o'zini tekshirishga
/// qaratilgan bo'lgani uchun, onboarding "allaqachon tugallangan" deb
/// oldindan (SharedPreferences mock orqali) belgilanadi — shunda
/// AppStartupGate to'g'ridan-to'g'ri HomeScreen'ni ko'rsatadi.
void main() {
  testWidgets('AzonTrainerApp Home ekranini ko\'rsatadi', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});

    await tester.pumpWidget(const AzonTrainerApp());
    await tester.pumpAndSettle();

    expect(find.text('Azon Trainer'), findsOneWidget);
    expect(find.text('Azon'), findsOneWidget);
    expect(find.text('Bomdod azoni'), findsOneWidget);
    expect(find.text('Iqomat'), findsOneWidget);
  });
}
