import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/phrase_catalog.dart';
import '../models/maqam.dart';
import '../models/phrase.dart';
import '../models/prayer_time.dart';
import 'full_adhan_preview_screen.dart';

/// v1.18: tanlash uchun mavjud 8 ta maqom — bular
/// `MaqamReferenceCatalog`da jumla-darajasida TO'LIQ qamrab olingan
/// (har biri uchun barcha 8 jumla mavjud). Bu ro'yxat
/// `FullMaqamAdhanCatalog`dan MUSTAQIL — chunki maqom tanlash
/// jumla-darajasidagi audio mavjudligiga bog'liq, "to'liq, uzluksiz
/// namuna" mavjudligiga emas (ikkinchisi ixtiyoriy, mavjud bo'lmasa
/// ham mashq qilish ishlaydi).
const List<Maqam> _selectableMaqams = [
  Maqam.bayati,
  Maqam.ajam,
  Maqam.kurd,
  Maqam.hijaz,
  Maqam.lami,
  Maqam.nahawand,
  Maqam.rast,
  Maqam.saba,
];

/// v1.17: maqomni SESSIYA darajasida bir marta tanlash uchun ekran.
/// Bu yerda tanlangan maqom butun mashq sessiyasi davomida o'zgarmay
/// qoladi — `PhrasePracticeScreen`dagi eski, har-jumla-alohida
/// ChoiceChip tanlovchisi olib tashlandi.
class MaqamSelectionScreen extends StatelessWidget {
  final String sessionTitle;
  final bool isBomdod;
  final bool isIqomat;

  /// v1.17: Azon oqimida `PrayerTimeSelectionScreen`dan keladi.
  /// Hozircha faqat SAQLANADI (kelajakda har bir namoz uchun alohida
  /// konfiguratsiya qo'shish imkoniyati uchun) — hech qanday kontent
  /// yoki audio tanlovga ta'sir qilmaydi.
  final PrayerTime? prayerTime;

  const MaqamSelectionScreen({
    super.key,
    required this.sessionTitle,
    this.isBomdod = false,
    this.isIqomat = false,
    this.prayerTime,
  });

  List<Phrase> get _phrases {
    if (isIqomat) return PhraseCatalog.iqomat;
    return PhraseCatalog.azonSequence(isBomdod: isBomdod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$sessionTitle — Maqom')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Mashq qilishdan oldin maqomni tanlang. Tanlangan maqom '
            'butun mashq davomida saqlanadi.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (final maqam in _selectableMaqams) ...[
            _MaqamCard(
              maqam: maqam,
              hasFullAudio: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullAdhanPreviewScreen(
                    sessionTitle: sessionTitle,
                    maqam: maqam,
                    phrases: _phrases,
                    isIqomat: isIqomat,
                    prayerTime: prayerTime,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MaqamCard extends StatelessWidget {
  final Maqam maqam;
  final bool hasFullAudio;
  final VoidCallback onTap;

  const _MaqamCard({
    required this.maqam,
    required this.hasFullAudio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: const Icon(Icons.music_note, color: AppTheme.primary),
        ),
        title: Text(
          maqam.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          hasFullAudio
              ? 'To\'liq azon namunasi mavjud'
              : 'To\'liq namuna hali mavjud emas',
          style: TextStyle(
            fontSize: 12,
            color: hasFullAudio ? Colors.green[700] : Colors.black38,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
