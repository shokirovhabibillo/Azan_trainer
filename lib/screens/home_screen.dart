import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/phrase_catalog.dart';
import 'onboarding_screen.dart';
import 'practice_screen.dart';

enum HomeMode { azon, bomdod, iqomat }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Azon Trainer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Muhim ma\'lumotlar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OnboardingScreen(isReviewMode: true),
              ),
            ),
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

  void _openPractice(BuildContext context, HomeMode mode) {
    final phrases = switch (mode) {
      HomeMode.azon => PhraseCatalog.azonSequence(isBomdod: false),
      HomeMode.bomdod => PhraseCatalog.azonSequence(isBomdod: true),
      HomeMode.iqomat => PhraseCatalog.iqomat,
    };
    final title = switch (mode) {
      HomeMode.azon => 'Azon',
      HomeMode.bomdod => 'Bomdod azoni',
      HomeMode.iqomat => 'Iqomat',
    };
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeScreen(title: title, phrases: phrases),
      ),
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
