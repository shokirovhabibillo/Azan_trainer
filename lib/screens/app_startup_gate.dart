import 'package:flutter/material.dart';

import '../services/onboarding_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// v1.13: ilova ishga tushganda birinchi ko'rsatiladigan "eshik" —
/// onboarding tugallangan-tugallanmaganini tekshiradi va shunga qarab
/// `OnboardingScreen` yoki `HomeScreen`ni ko'rsatadi.
///
/// Mavjud Azon/Bomdod/Iqomat/recording/pitch/duration arxitekturasiga
/// hech qanday tegilmaydi — faqat ilovaning ENG BOSHIDA qaysi ekran
/// ko'rsatilishini hal qiladi.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  final _onboardingService = OnboardingService();
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final completed = await _onboardingService.isCompleted();
    if (!mounted) return;
    setState(() => _onboardingCompleted = completed);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingCompleted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _onboardingCompleted!
        ? const HomeScreen()
        : const OnboardingScreen();
  }
}
