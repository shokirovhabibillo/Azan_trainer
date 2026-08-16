import 'package:flutter/material.dart';

/// v1.16: mashq qilish ekranida ko'rsatiladigan amaliy eslatma.
class PhraseEtiquetteHint {
  final String text;
  final IconData icon;

  const PhraseEtiquetteHint({required this.text, required this.icon});
}

/// v1.16: jumla ID -> amaliy eslatma xaritasi. Faqat "Hayya
/// 'alas-salah" (o'ng) va "Hayya 'alal-falah" (chap) uchun aniq
/// yo'nalish ko'rsatmasi mavjud — bu Azon va Iqomatning ikkalasida
/// ham bir xil qoidaga amal qiladi (Hanafiy amaliyoti).
const Map<String, PhraseEtiquetteHint> phraseEtiquetteHints = {
  'azon_hayya_alas_solah': PhraseEtiquetteHint(
    text: 'O\'ng tomonga burilib ayting',
    icon: Icons.turn_right,
  ),
  'azon_hayya_alal_falah': PhraseEtiquetteHint(
    text: 'Chap tomonga burilib ayting',
    icon: Icons.turn_left,
  ),
  'iqomat_hayya_alas_solah': PhraseEtiquetteHint(
    text: 'O\'ng tomonga burilib ayting',
    icon: Icons.turn_right,
  ),
  'iqomat_hayya_alal_falah': PhraseEtiquetteHint(
    text: 'Chap tomonga burilib ayting',
    icon: Icons.turn_left,
  ),
};
