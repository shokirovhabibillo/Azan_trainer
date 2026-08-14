import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/app_startup_gate.dart';

void main() {
  runApp(const AzonTrainerApp());
}

class AzonTrainerApp extends StatelessWidget {
  const AzonTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Azon Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppStartupGate(),
    );
  }
}
