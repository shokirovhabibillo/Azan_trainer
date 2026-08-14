import 'package:flutter/widgets.dart';

/// v1.13: onboarding matnini o'qimasdan "bir zumda" pastga surib
/// yuborishning oldini olish uchun — fling (barmoqni tez surib
/// qo'yib yuborish) tezligini cheklaydi.
///
/// MUHIM: bu FAQAT tezlashtirilgan "otilish" (ballistic) harakatini
/// cheklaydi — foydalanuvchi barmog'i bilan ODATIY tortib scroll
/// qilishi (drag) va yuqoriga qaytib qayta o'qishi erkin, cheklanmagan
/// qolaveradi. Asosiy himoya esa bu emas, balki `OnboardingScreen`dagi
/// minimal o'qish vaqti — bu shunchaki qo'shimcha, yordamchi chora.
class LimitedFlingScrollPhysics extends ClampingScrollPhysics {
  const LimitedFlingScrollPhysics({super.parent});

  /// Maksimal ruxsat etilgan fling tezligi (piksel/soniya). Odatiy
  /// tez fling ~3000-8000 px/s bo'lishi mumkin — buni sezilarli
  /// pasaytiramiz, lekin butunlay o'chirib qo'ymaymiz (tabiiy
  /// tuyulishi uchun).
  static const double _maxFlingVelocity = 900.0;

  @override
  LimitedFlingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LimitedFlingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    double cappedVelocity = velocity;
    if (cappedVelocity > _maxFlingVelocity) {
      cappedVelocity = _maxFlingVelocity;
    } else if (cappedVelocity < -_maxFlingVelocity) {
      cappedVelocity = -_maxFlingVelocity;
    }
    return super.createBallisticSimulation(position, cappedVelocity);
  }
}
