import 'package:shared_preferences/shared_preferences.dart';

/// v1.13: majburiy onboarding ko'rsatilgan-ko'rsatilmaganini saqlaydi.
/// Mavjud `ProgressService` bilan bir xil (SharedPreferences asosidagi)
/// naqshga amal qiladi — yangi dependency yoki alohida storage
/// mexanizmi kiritilmadi.
class OnboardingService {
  static const _completedKey = 'onboarding_completed';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  /// Faqat test/diagnostika uchun — ishlab chiqarish kodida
  /// ishlatilmaydi.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }
}
