// lib/data/repository/session_repository.dart
import 'dart:developer';
import 'package:dailymoji/data/dtos/session_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStat {
  final DateTime day; // KST 자정
  final double? max;
  final double? min;
  final double? avg;

  const DailyStat({required this.day, this.max, this.min, this.avg});
}

class SessionRepository {
  final SupabaseClient _client;

  SessionRepository(this._client);

  static const _table = 'sessions';
  static const _cols = 'created_at, user_id, g_score';

  /// 외부에서 한 번만 호출하면 1~3단계를 모두 수행해 반환합니다.
  Future<List<DailyStat>> fetchDailyStatsLast14Days({
    required String userId,
    DateTime? now,
    bool fillMissingWithZero = false, // true면 데이터 없는 날을 0,0,0으로 채움
  }) async {
    final _now = now ?? DateTime.now();
    final endAtUtc = _now.toUtc();
    final startAtUtc = endAtUtc.subtract(const Duration(days: 14));

    final sessions = await _fetchRawLast14Days(
      userId: userId,
      startAtUtc: startAtUtc,
      endAtUtc: endAtUtc,
    );

    return _computeDailyStatsKst(
      sessions14d: sessions,
      startAtUtc: startAtUtc,
      endAtUtc: endAtUtc,
      fillMissingWithZero: fillMissingWithZero,
    );
  }

  // ===== 1) 최근 14일 raw 세션 가져오기 =====
  Future<List<SessionDto>> _fetchRawLast14Days({
    required String userId,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
  }) async {
    try {
      final query = _client
          .from(_table)
          .select(_cols)
          .eq('user_id', userId)
          .gte('created_at', startAtUtc.toIso8601String())
          .lt('created_at', endAtUtc.toIso8601String())
          .order('created_at', ascending: true);

      final List<dynamic> rows = await query;
      return rows
          .cast<Map<String, dynamic>>()
          .map(SessionDto.fromJson)
          .toList();
    } on PostgrestException catch (e, s) {
      log('_fetchRawLast14Days PostgrestException: ${e.message}',
          stackTrace: s);
      rethrow;
    } catch (e, s) {
      log('_fetchRawLast14Days Unknown error: $e', stackTrace: s);
      rethrow;
    }
  }

  // ===== 2+3) 날짜(KST) 버킷팅 + max/min/avg 계산 =====
  List<DailyStat> _computeDailyStatsKst({
    required List<SessionDto> sessions14d,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    required bool fillMissingWithZero,
  }) {
    // 2-1) 14일 키(자정 KST) 미리 생성
    final startKst = _toKstMidnight(startAtUtc);
    final endKst = _toKstMidnight(endAtUtc);
    final map = <DateTime, List<double>>{};

    for (DateTime d = startKst;
        !d.isAfter(endKst.subtract(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))) {
      map[d] = <double>[];
    }

    // 2-2) 세션을 해당 날짜 바구니에 담기
    for (final s in sessions14d) {
      if (s.createdAt == null || s.gScore == null) continue;
      final kst = s.createdAt!.toUtc().add(const Duration(hours: 9));
      final key = DateTime(kst.year, kst.month, kst.day);
      if (map.containsKey(key)) {
        map[key]!.add(s.gScore!);
      }
    }

    // 3) 각 날짜별 max/min/avg 계산
    final result = <DailyStat>[];
    final keys = map.keys.toList()..sort((a, b) => a.compareTo(b));

    for (final day in keys) {
      final scores = map[day]!..sort();
      if (scores!.isEmpty) {
        result.add(
          fillMissingWithZero
              ? DailyStat(day: day, max: 0, min: 0, avg: 0)
              : DailyStat(day: day, max: null, min: null, avg: null),
        );
        continue;
      }
      final max = scores.last;
      final min = scores.first;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      result.add(DailyStat(day: day, max: max, min: min, avg: avg));
    }
    return result;
  }

  // UTC/로컬 어떤 값이 와도 KST 자정으로 내림
  DateTime _toKstMidnight(DateTime dt) {
    final kst = dt.toUtc().add(const Duration(hours: 9));
    return DateTime(kst.year, kst.month, kst.day);
  }
}
