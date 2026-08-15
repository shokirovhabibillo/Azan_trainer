import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/azon_etiquette_content.dart';

/// v1.16: "Azon aytish tartibi va odoblari" — Home ekranidan istalgan
/// payt ochiladigan, majburiy bo'lmagan (onboarding'dagi kabi o'qish
/// tezligi cheklovi yo'q) oddiy ma'lumot ekrani.
class AzonEtiquetteScreen extends StatelessWidget {
  const AzonEtiquetteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Azon odoblari')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                azonEtiquetteIntro,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              for (final item in azonEtiquetteItems) ...[
                _EtiquetteCard(item: item),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EtiquetteCard extends StatelessWidget {
  final AzonEtiquetteItem item;

  const _EtiquetteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.body,
            style: const TextStyle(fontSize: 14.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
