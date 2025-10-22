// lib/presentation/nudge/nudge_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class NudgeStorage {
  static const _kSnoozeUntil = 'emotion_nudge_snooze_until';

  Future<DateTime?> getSnoozeUntil() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSnoozeUntil);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> snoozeDays(int days) async {
    final p = await SharedPreferences.getInstance();
    final until =
        DateTime.now().toUtc().add(Duration(days: days)).toIso8601String();
    await p.setString(_kSnoozeUntil, until);
  }

  Future<void> clearSnooze() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSnoozeUntil);
  }
}
