import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/practice_session.dart';

/// Foydalanuvchi progressini (mashq tarixi) qurilmada lokal saqlaydi.
/// Kelajakda bu klass Supabase kabi masofaviy sync bilan almashtirilishi
/// yoki kengaytirilishi mumkin — UI shu interfeys orqali ishlaganicha
/// qoladi.
class ProgressService {
  static const _sessionsKey = 'practice_sessions_v1';

  Future<void> saveSession(PracticeSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_sessionsKey) ?? [];
    existing.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_sessionsKey, existing);
  }

  Future<List<PracticeSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_sessionsKey) ?? [];
    return raw
        .map((s) => PracticeSession.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  Future<int> countForPhrase(String phraseId) async {
    final sessions = await loadSessions();
    return sessions.where((s) => s.phraseId == phraseId).length;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}
