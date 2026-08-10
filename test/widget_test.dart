import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:azon_trainer/main.dart';

/// Oddiy "smoke test" — ilova ishga tushganda Home ekrani va asosiy
/// navigatsiya elementlari ko'rinishini tekshiradi.
///
/// MUHIM: bu faylning mavjudligi `flutter create` buyrug'i CI'da
/// o'zining standart (va noto'g'ri paket nomiga ishora qiluvchi)
/// widget_test.dart shablonini yaratishining oldini oladi — `flutter
/// create` bu faylni faqat u mavjud bo'lmaganda generatsiya qiladi.
void main() {
  testWidgets('AzonTrainerApp Home ekranini ko\'rsatadi', (tester) async {
    await tester.pumpWidget(const AzonTrainerApp());

    expect(find.text('Azon Trainer'), findsOneWidget);
    expect(find.text('Azon'), findsOneWidget);
    expect(find.text('Bomdod azoni'), findsOneWidget);
    expect(find.text('Iqomat'), findsOneWidget);
  });
}
