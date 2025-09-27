// gscore_service.dart
import 'package:dailymoji/data/dtos/session_dto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// EmotionData는 네 UI 파일에 이미 있는 모델 그대로 import 해와도 되고,
// 여기서 재정의해도 됨. (아래는 네 모델 시그니처에 맞춘 것)
class EmotionData {
  final Color color;
  final List<FlSpot> spots;
  final String description;
  final double avg; // 14일 전체 평균(일별 평균값들의 평균)
  final double max; // 14일 일별 평균 중 최댓값
  final double min; // 14일 일별 평균 중 최솟값

  EmotionData({
    required this.color,
    required this.spots,
    required this.description,
    required this.avg,
    required this.max,
    required this.min,
  });
}

class GScoreEmotionResult {
  final List<DateTime> days; // 길이 14, 오래된 → 최신
  final EmotionData? emotion; // 데이터 없으면 null
  GScoreEmotionResult(this.days, this.emotion);
}

class GScoreService {
  final SupabaseClient client;
  GScoreService(this.client);

  // 0~1 → 0~10, 소수 1자리 반올림 + 0~10 클램프
  double _scaleToTen(num v) {
    final scaled = v * 10;
    final one = (scaled * 10).round() / 10.0;
    if (one < 0) return 0.0;
    if (one > 10) return 10.0;
    return one;
  }

  double? _meanIgnoreNulls(List<double?> xs) {
    final v = xs.whereType<double>().toList();
    if (v.isEmpty) return null;
    final s = v.fold<double>(0, (a, b) => a + b);
    return s / v.length;
  }

  double? _minIgnoreNulls(List<double?> xs) {
    final v = xs.whereType<double>().toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a < b ? a : b);
  }

  double? _maxIgnoreNulls(List<double?> xs) {
    final v = xs.whereType<double>().toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a > b ? a : b);
  }

  /// userId 기준 최근 14일 g_score 집계 → EmotionData
  /// - 빈 날은 null로 유지(0으로 채우지 않음)
  /// - 차트 spots는 값이 있는 날만 FlSpot 추가(중간이 비면 선이 건너뜀)
  Future<GScoreEmotionResult> fetch14DaysAsEmotionData({
    required String userId,
    required Color color,
    String description = "종합 감정 점수 입니다.",
  }) async {
    // 기간: 오늘 00:00(UTC) 기준 14일 전 ~ 내일 00:00
    final now = DateTime.now().toUtc();
    final today0 = DateTime.utc(now.year, now.month, now.day);
    final start = today0.subtract(const Duration(days: 14));
    final end = today0.add(const Duration(days: 1));

    // 타임라인(길이 14)
    final days = List.generate(14, (i) => start.add(Duration(days: i)));

    // Supabase 쿼리 (sessions: user_id, created_at, g_score)
    final res = await client
        .from('sessions')
        .select('user_id, created_at, g_score')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());

    if (res is! List) return GScoreEmotionResult(days, null);

    // 날짜별 버킷
    final Map<DateTime, List<double>> bucket = {};
    for (final row in res.cast<Map<String, dynamic>>()) {
      final dto = SessionDto.fromJson(row);
      if (dto.createdAt == null || dto.gScore == null) continue;
      final utc = dto.createdAt!.toUtc();
      final dayKey = DateTime.utc(utc.year, utc.month, utc.day);
      bucket.putIfAbsent(dayKey, () => []).add(dto.gScore!);
    }

    // 일별 평균(0~1), 비어 있으면 null
    final List<double?> avgPerDay0to1 = List.generate(14, (i) {
      final vs = bucket[days[i]] ?? const <double>[];
      if (vs.isEmpty) return null;
      return vs.fold<double>(0, (a, b) => a + b) / vs.length;
    });

    // 카드용 집계(일별 평균들만 대상으로 평균/최소/최대)
    final mean0to1 = _meanIgnoreNulls(avgPerDay0to1);
    final min0to1 = _minIgnoreNulls(avgPerDay0to1);
    final max0to1 = _maxIgnoreNulls(avgPerDay0to1);

    if (mean0to1 == null && min0to1 == null && max0to1 == null) {
      // 14일 내 데이터 전무
      return GScoreEmotionResult(days, null);
    }

    // 차트용 spots (값 있는 날만)
    final spots = <FlSpot>[];
    for (var i = 0; i < avgPerDay0to1.length; i++) {
      final v = avgPerDay0to1[i];
      if (v == null) continue;
      spots.add(FlSpot(i.toDouble(), _scaleToTen(v)));
    }

    final emotion = EmotionData(
      color: color,
      spots: spots,
      description: description,
      avg: mean0to1 == null ? 0 : _scaleToTen(mean0to1),
      min: min0to1 == null ? 0 : _scaleToTen(min0to1),
      max: max0to1 == null ? 0 : _scaleToTen(max0to1),
    );

    return GScoreEmotionResult(days, emotion);
  }
}
