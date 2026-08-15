import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'azon_etiquette_screen.dart';
import 'maqam_selection_screen.dart';
import 'onboarding_screen.dart';
import 'prayer_time_selection_screen.dart';

enum HomeMode { azon, bomdod, iqomat }

enum _InfoMenuItem { importantInfo, etiquette }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Azon Trainer'),
        actions: [
          PopupMenuButton<_InfoMenuItem>(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Ma\'lumot',
            onSelected: (item) => _openInfo(context, item),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _InfoMenuItem.importantInfo,
                child: Text('Muhim ma\'lumotlar'),
              ),
              PopupMenuItem(
                value: _InfoMenuItem.etiquette,
                child: Text('Azon odoblari'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.mosque, size: 64, color: AppTheme.primary),
          const SizedBox(height: 8),
          const Text(
            'Azon va Iqomat talaffuzini mashq qiling',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 28),
          _ModeCard(
            title: 'Azon',
            subtitle: 'Kundalik azon jumlalari',
            icon: Icons.volume_up,
            onTap: () => _openPractice(context, HomeMode.azon),
          ),
          _ModeCard(
            title: 'Bomdod azoni',
            subtitle: '"As-solaatu khoyrum minan-navm" bilan',
            icon: Icons.wb_twilight,
            onTap: () => _openPractice(context, HomeMode.bomdod),
          ),
          _ModeCard(
            title: 'Iqomat',
            subtitle: 'Namoz boshlanishidan oldin',
            icon: Icons.play_circle_outline,
            onTap: () => _openPractice(context, HomeMode.iqomat),
          ),
        ],
      ),
    );
  }

  void _openInfo(BuildContext context, _InfoMenuItem item) {
    final screen = switch (item) {
      _InfoMenuItem.importantInfo =>
        const OnboardingScreen(isReviewMode: true),
      _InfoMenuItem.etiquette => const AzonEtiquetteScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// v1.17: Azon/Bomdod/Iqomat endi to'g'ridan-to'g'ri PracticeScreen'ga
  /// emas, yangi oqim orqali o'tadi:
  ///   Azon: Peshin/Asr/Shom/Xufton -> Maqom tanlash -> To'liq namuna
  ///   Bomdod/Iqomat: Maqom tanlash -> To'liq namuna
  /// PracticeScreen (mashq oynasi) o'zi — o'zgarishsiz qoladi, faqat
  /// endi tanlangan maqom bilan ochiladi.
  void _openPractice(BuildContext context, HomeMode mode) {
    final Widget screen = switch (mode) {
      HomeMode.azon => const PrayerTimeSelectionScreen(),
      HomeMode.bomdod => const MaqamSelectionScreen(
          sessionTitle: 'Bomdod azoni',
          isBomdod: true,
        ),
      HomeMode.iqomat => const MaqamSelectionScreen(
          sessionTitle: 'Iqomat',
          isIqomat: true,
        ),
    };
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
