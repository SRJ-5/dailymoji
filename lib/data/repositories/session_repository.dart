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

// RIN: RPC 응답(JSON)에서 DailyStat 객체로 변환하기 위한 factory 생성자 추가
  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      day: DateTime.parse(json['day']),
      max: (json['max_g_score'] as num?)?.toDouble(),
      min: (json['min_g_score'] as num?)?.toDouble(),
      avg: (json['avg_g_score'] as num?)?.toDouble(),
    );
  }
}

class SessionRepository {
  final SupabaseClient _client;

  SessionRepository(this._client);

// RIN: 클라이언트에서 직접 통계를 계산하는 로직에서 Supabase 사용하는 로직으로 변경
  // Supabase RPC를 호출하여 이미 계산된 통계 데이터를 가져옵니다.
  // Supabase 프로젝트에 있는 'get_daily_gscore_stats' 함수 활용
  Future<List<DailyStat>> fetchDailyStatsLast14Days({
    required String userId,
    DateTime? now,
    bool fillMissingWithZero = false, // 이 옵션은 이제 서버 함수 로직에 따라 달라집니다.
  }) async {
    try {
      final _now = now ?? DateTime.now();
      // 🧡 서버 함수에 전달할 시작일과 종료일을 ISO 8601 형식의 문자열로 준비합니다.
      final endDate = _now.toUtc();
      final startDate = endDate.subtract(const Duration(days: 14));

      final List<dynamic> response = await _client.rpc(
        'get_daily_gscore_stats',
        params: {
          'p_user_id': userId,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
        },
      );

      // 🧡 RPC 호출 결과를 DailyStat 객체 리스트로 변환합니다.
      return response
          .cast<Map<String, dynamic>>()
          .map(DailyStat.fromJson)
          .toList();
    } on PostgrestException catch (e, s) {
      log('fetchDailyStatsLast14Days PostgrestException: ${e.message}',
          stackTrace: s);
      rethrow;
    } catch (e, s) {
      log('fetchDailyStatsLast14Days Unknown error: $e', stackTrace: s);
      rethrow;
    }
  }

  // 아래의 _fetchRawLast14Days, _computeDailyStatsKst, _toKstMidnight 함수들은
  // 이제 서버에서 계산을 처리하는걸로 대체!!
}

//   static const _table = 'sessions';
//   static const _cols = 'created_at, user_id, g_score';

//   /// 외부에서 한 번만 호출하면 1~3단계를 모두 수행해 반환합니다.
//   Future<List<DailyStat>> fetchDailyStatsLast14Days({
//     required String userId,
//     DateTime? now,
//     bool fillMissingWithZero = false, // true면 데이터 없는 날을 0,0,0으로 채움
//   }) async {
//     final _now = now ?? DateTime.now();
//     final endAtUtc = _now.toUtc();
//     final startAtUtc = endAtUtc.subtract(const Duration(days: 14));

//     final sessions = await _fetchRawLast14Days(
//       userId: userId,
//       startAtUtc: startAtUtc,
//       endAtUtc: endAtUtc,
//     );

//     return _computeDailyStatsKst(
//       sessions14d: sessions,
//       startAtUtc: startAtUtc,
//       endAtUtc: endAtUtc,
//       fillMissingWithZero: fillMissingWithZero,
//     );
//   }

//   // ===== 1) 최근 14일 raw 세션 가져오기 =====
//   Future<List<SessionDto>> _fetchRawLast14Days({
//     required String userId,
//     required DateTime startAtUtc,
//     required DateTime endAtUtc,
//   }) async {
//     try {
//       final query = _client
//           .from(_table)
//           .select(_cols)
//           .eq('user_id', userId)
//           .gte('created_at', startAtUtc.toIso8601String())
//           .lt('created_at', endAtUtc.toIso8601String())
//           .order('created_at', ascending: true);

//       final List<dynamic> rows = await query;
//       return rows
//           .cast<Map<String, dynamic>>()
//           .map(SessionDto.fromJson)
//           .toList();
//     } on PostgrestException catch (e, s) {
//       log('_fetchRawLast14Days PostgrestException: ${e.message}',
//           stackTrace: s);
//       rethrow;
//     } catch (e, s) {
//       log('_fetchRawLast14Days Unknown error: $e', stackTrace: s);
//       rethrow;
//     }
//   }

//   // ===== 2+3) 날짜(KST) 버킷팅 + max/min/avg 계산 =====
//   List<DailyStat> _computeDailyStatsKst({
//     required List<SessionDto> sessions14d,
//     required DateTime startAtUtc,
//     required DateTime endAtUtc,
//     required bool fillMissingWithZero,
//   }) {
//     // 2-1) 14일 키(자정 KST) 미리 생성
//     final startKst = _toKstMidnight(startAtUtc);
//     final endKst = _toKstMidnight(endAtUtc);
//     final map = <DateTime, List<double>>{};

//     for (DateTime d = startKst;
//         !d.isAfter(endKst.subtract(const Duration(days: 1)));
//         d = d.add(const Duration(days: 1))) {
//       map[d] = <double>[];
//     }

//     // 2-2) 세션을 해당 날짜 바구니에 담기
//     for (final s in sessions14d) {
//       if (s.createdAt == null || s.gScore == null) continue;
//       final kst = s.createdAt!.toUtc().add(const Duration(hours: 9));
//       final key = DateTime(kst.year, kst.month, kst.day);
//       if (map.containsKey(key)) {
//         map[key]!.add(s.gScore!);
//       }
//     }

//     // 3) 각 날짜별 max/min/avg 계산
//     final result = <DailyStat>[];
//     final keys = map.keys.toList()..sort((a, b) => a.compareTo(b));

//     for (final day in keys) {
//       final scores = map[day]!..sort();
//       if (scores!.isEmpty) {
//         result.add(
//           fillMissingWithZero
//               ? DailyStat(day: day, max: 0, min: 0, avg: 0)
//               : DailyStat(day: day, max: null, min: null, avg: null),
//         );
//         continue;
//       }
//       final max = scores.last;
//       final min = scores.first;
//       final avg = scores.reduce((a, b) => a + b) / scores.length;
//       result.add(DailyStat(day: day, max: max, min: min, avg: avg));
//     }
//     return result;
//   }

//   // UTC/로컬 어떤 값이 와도 KST 자정으로 내림
//   DateTime _toKstMidnight(DateTime dt) {
//     final kst = dt.toUtc().add(const Duration(hours: 9));
//     return DateTime(kst.year, kst.month, kst.day);
//   }
// }
