import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:azon_trainer/services/onboarding_service.dart';

void main() {
  group('OnboardingService', () {
    test('yangi o\'rnatishda isCompleted false qaytaradi', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService();
      expect(await service.isCompleted(), isFalse);
    });

    test('markCompleted chaqirilgandan keyin isCompleted true bo\'ladi',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService();

      expect(await service.isCompleted(), isFalse);
      await service.markCompleted();
      expect(await service.isCompleted(), isTrue);
    });

    test('reset() holatni tozalaydi', () async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final service = OnboardingService();

      expect(await service.isCompleted(), isTrue);
      await service.reset();
      expect(await service.isCompleted(), isFalse);
    });

    test('avvaldan true bo\'lib kelgan holat to\'g\'ri o\'qiladi', () async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final service = OnboardingService();
      expect(await service.isCompleted(), isTrue);
    });
  });
}
