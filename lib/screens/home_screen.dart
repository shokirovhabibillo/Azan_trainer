import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/phrase_catalog.dart';
import 'azon_dua_screen.dart';
import 'azon_etiquette_screen.dart';
import 'onboarding_screen.dart';
import 'practice_screen.dart';
import 'prayer_time_selection_screen.dart';

enum _InfoMenuItem { importantInfo, etiquette }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      // v1.25: "emerald_mihrab" foni — SVG'dan PNG'ga aylantirilgan
      // (yangi flutter_svg dependency qo'shmasdan). Markazi ataylab
      // sokin qoldirilgan (manba README'siga ko'ra), shuning uchun
      // ustiga oq kartalar/och matn qo'yish uchun mo'ljallangan.
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/emerald_mihrab.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.mosque, size: 64, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'Azon va Iqomat talaffuzini mashq qiling',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 28),
                // v1.22: Bomdod endi alohida karta emas — Azon
                // oqimidagi namoz vaqti tanlovida (5-variant
                // sifatida) mavjud.
                _ModeCard(
                  title: 'Azon',
                  subtitle: 'Peshin, Asr, Shom, Xufton, Bomdod',
                  icon: Icons.volume_up,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrayerTimeSelectionScreen(),
                    ),
                  ),
                ),
                // v1.22: Iqomat maqomga bog'liq emas (tez aytiladi,
                // ohang farqi ahamiyatsiz) — shuning uchun maqom
                // tanlashsiz, to'g'ridan-to'g'ri mashqqa o'tadi.
                _ModeCard(
                  title: 'Iqomat',
                  subtitle: 'Namoz boshlanishidan oldin',
                  icon: Icons.play_circle_outline,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PracticeScreen(
                        title: 'Iqomat',
                        phrases: PhraseCatalog.iqomat,
                      ),
                    ),
                  ),
                ),
                // v1.22: yangi — Iqomatdan keyingi ro'yxatda, azon
                // eshitilgandan/aytilgandan keyin o'qiladigan duo.
                _ModeCard(
                  title: 'Azon duosi',
                  subtitle: 'Azondan keyin o\'qiladigan duo',
                  icon: Icons.menu_book,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AzonDuaScreen()),
                  ),
                ),
              ],
            ),
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
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
