import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/prayer_time.dart';
import 'maqam_selection_screen.dart';

/// v1.22: Azon uchun namoz vaqtini tanlash — endi Bomdod (Fajr) ham
/// shu ro'yxatda (5 ta namoz), alohida Home rejimi emas.
class PrayerTimeSelectionScreen extends StatelessWidget {
  const PrayerTimeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Azon — namoz vaqti')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final time in PrayerTime.values) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1F2E7D32),
                  child: Icon(Icons.schedule, color: AppTheme.primary),
                ),
                title: Text(
                  time.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MaqamSelectionScreen(
                      sessionTitle: 'Azon — ${time.label}',
                      prayerTime: time,
                    ),
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
