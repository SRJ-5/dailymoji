import 'dart:convert';

import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/domain/entities/weekly_summary.dart';
import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/domain/enums/cluster_type.dart';
import 'package:dailymoji/domain/enums/metric.dart';
import 'package:dailymoji/presentation/pages/report/weekly_report.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';
import 'package:dailymoji/domain/use_cases/cluster_use_case/get_14day_cluster_scores_use_case.dart';
import 'package:dailymoji/domain/models/cluster_stats_models.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/providers/today_cluster_scores_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

/// ----- State -----
class ClusterScoresState {
  final bool isLoading;
  final List<ClusterScore> scores; // 오늘 데이터(기존)
  final String? error;

  // 차트용(14일 집계 결과 변환본)
  final List<DateTime> days; // x축(오래된 → 최신)
  final Map<String, EmotionData> emotionMap; // "불안/분노" 등 → EmotionData

  final WeeklySummary? weeklySummary;

  ClusterScoresState({
    required this.isLoading,
    required this.scores,
    required this.days,
    required this.emotionMap,
    this.weeklySummary,
    this.error,
  });

  factory ClusterScoresState.initial() => ClusterScoresState(
        isLoading: false,
        scores: const [],
        days: const [],
        emotionMap: const {},
        weeklySummary: null,
      );

  ClusterScoresState copyWith({
    bool? isLoading,
    List<ClusterScore>? scores,
    String? error,
    List<DateTime>? days,
    Map<String, EmotionData>? emotionMap,
    WeeklySummary? weeklySummary,
  }) {
    return ClusterScoresState(
      isLoading: isLoading ?? this.isLoading,
      scores: scores ?? this.scores,
      error: error,
      days: days ?? this.days,
      emotionMap: emotionMap ?? this.emotionMap,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }
}

/// ----- ViewModel -----
class ClusterScoresViewModel extends StateNotifier<ClusterScoresState> {
  final Get14DayClusterStatsUseCase _getAgg14UC;

  ClusterScoresViewModel(this._getAgg14UC)
      : super(ClusterScoresState.initial());

  /// 주간 요약을 받아오는 private 메서드 추가
  Future<WeeklySummary?> _fetchWeeklySummary(String userId) async {
    // ignore: avoid_print
    print('[weekly-summary] start userId=$userId');

    final uri = Uri.parse('${ApiConfig.baseUrl}/report/weekly-summary');
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(milliseconds: 5000));
      // ignore: avoid_print
      print('[weekly-summary] status=${resp.statusCode}');

      if (resp.statusCode != 200) {
        return null;
      }
      final decoded = utf8.decode(resp.bodyBytes);
      // ignore: avoid_print
      print('[weekly-summary] body=$decoded');
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      return WeeklySummary.fromJson(data);
    } catch (e) {
      // 네트워크/타임아웃/JSON 에러 시 조용히 null 반환 -> 기본 문구로 대체
      // ignore: avoid_print
      print('[weekly-summary] error=$e');
      return null;
    }
  }

  /// 14일 집계 로드 → EmotionData로 변환(차트/카드 용도)
  Future<void> load14DayChart(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fSummary = _fetchWeeklySummary(userId);
      final fAgg = _getAgg14UC.execute(userId: userId);

      final summary = await fSummary;
      final agg = await fAgg;

      final emap = _buildEmotionMap(agg, summary); // ← 시그니처 변경
      state =
          state.copyWith(isLoading: false, days: agg.days, emotionMap: emap);
    } catch (e, st) {
      // ignore: avoid_print
      print('[load14DayChart] error=$e\n$st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
    // try {
    //   final agg = await _getAgg14UC.execute(userId: userId);
    //   final emap = _buildEmotionMap(agg);
    //   state = state.copyWith(isLoading: false, days: agg.days, emotionMap: emap);
    // } catch (e) {
    //   state = state.copyWith(isLoading: false, error: e.toString());
    // }
  }

  /// 모든 지표(avg/min/max)가 동시에 0 또는 null이면 -> null로 간주
  List<double?> _cleanMissingByTriplet(
    List<double?> avg,
    List<double?> min,
    List<double?> max,
  ) {
    final n = avg.length;
    return List<double?>.generate(n, (i) {
      final a = avg[i];
      final mi = min[i];
      final ma = max[i];
      final allNull = (a == null && mi == null && ma == null);
      final allZeroOrNull =
          ((a ?? 0) == 0) && ((mi ?? 0) == 0) && ((ma ?? 0) == 0);

      // 세 값이 전부 null이거나 전부 0이면 => 결측으로 본다
      if (allNull || allZeroOrNull) return null;

      // 그 외에는 원래 avg 값을 그대로 쓴다 (실제 0도 허용)
      return a;
    });
  }

  /// avg를 기준 마스크로 써서, avg가 null인 날은 다른 지표도 null로 맞춰준다
  List<double?> _applyMaskByAvg(List<double?> values, List<double?> avgMask) {
    final n = values.length;
    return List<double?>.generate(n, (i) {
      return avgMask[i] == null ? null : values[i];
    });
  }

  // ---------- 변환 유틸 ----------
  // 0~1 → 0~10 (소수 1자리 반올림, 0~10 클램프)
  double scaleToTen(num v) {
    final scaled = v * 10;
    final one = (scaled * 10).round() / 10.0; // 소수1자리
    return one.clamp(0.0, 10.0);
  }

  List<double> scaleList(Iterable<num> values) =>
      values.map(scaleToTen).toList();

  List<FlSpot> _toSpotsConnected(List<double?> ys) {
    final spots = <FlSpot>[];
    for (var i = 0; i < ys.length; i++) {
      final v = ys[i];
      if (v == null) continue; // ★ 포인트 자체를 만들지 않음 → 앞뒤가 연결됨
      spots.add(FlSpot(i.toDouble(), scaleToTen(v)));
    }
    return spots;
  }

// 기간 통계(평균/최저/최고)도 스케일링
  double _avgScaledOpt(List<double?> v) {
    final vals = [
      for (final e in v)
        if (e != null) e
    ];
    if (vals.isEmpty) return 0.0;
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    return scaleToTen(avg);
  }

  double _minScaledOpt(List<double?> v) {
    final vals = [
      for (final e in v)
        if (e != null) e
    ];
    if (vals.isEmpty) return 0.0;
    return scaleToTen(vals.reduce((a, b) => a < b ? a : b));
  }

  double _maxScaledOpt(List<double?> v) {
    final vals = [
      for (final e in v)
        if (e != null) e
    ];
    if (vals.isEmpty) return 0.0;
    return scaleToTen(vals.reduce((a, b) => a > b ? a : b));
  }

  Map<String, EmotionData> _buildEmotionMap(FourteenDayAgg agg,
      [WeeklySummary? s]) {
    // 원본(도메인) 리스트: List<double?> 라고 가정
    final nhAvg0 = agg.series[ClusterType.negHigh]![Metric.avg]!;
    final nhMin0 = agg.series[ClusterType.negHigh]![Metric.min]!;
    final nhMax0 = agg.series[ClusterType.negHigh]![Metric.max]!;

    final nlAvg0 = agg.series[ClusterType.negLow]![Metric.avg]!;
    final nlMin0 = agg.series[ClusterType.negLow]![Metric.min]!;
    final nlMax0 = agg.series[ClusterType.negLow]![Metric.max]!;

    final posAvg0 = agg.series[ClusterType.positive]![Metric.avg]!;
    final posMin0 = agg.series[ClusterType.positive]![Metric.min]!;
    final posMax0 = agg.series[ClusterType.positive]![Metric.max]!;

    final slAvg0 = agg.series[ClusterType.sleep]![Metric.avg]!;
    final slMin0 = agg.series[ClusterType.sleep]![Metric.min]!;
    final slMax0 = agg.series[ClusterType.sleep]![Metric.max]!;

    final adAvg0 = agg.series[ClusterType.adhd]![Metric.avg]!;
    final adMin0 = agg.series[ClusterType.adhd]![Metric.min]!;
    final adMax0 = agg.series[ClusterType.adhd]![Metric.max]!;

    // 1) “세 지표가 모두 0/NULL이면 null”로 정리
    final nhAvg = _cleanMissingByTriplet(nhAvg0, nhMin0, nhMax0);
    final nlAvg = _cleanMissingByTriplet(nlAvg0, nlMin0, nlMax0);
    final posAvg = _cleanMissingByTriplet(posAvg0, posMin0, posMax0);
    final slAvg = _cleanMissingByTriplet(slAvg0, slMin0, slMax0);
    final adAvg = _cleanMissingByTriplet(adAvg0, adMin0, adMax0);

    // 2) avg 마스크 기준으로 min/max도 맞춤
    final nhMin = _applyMaskByAvg(nhMin0, nhAvg);
    final nhMax = _applyMaskByAvg(nhMax0, nhAvg);

    final nlMin = _applyMaskByAvg(nlMin0, nlAvg);
    final nlMax = _applyMaskByAvg(nlMax0, nlAvg);

    final posMin = _applyMaskByAvg(posMin0, posAvg);
    final posMax = _applyMaskByAvg(posMax0, posAvg);

    final slMin = _applyMaskByAvg(slMin0, slAvg);
    final slMax = _applyMaskByAvg(slMax0, slAvg);

    final adMin = _applyMaskByAvg(adMin0, adAvg);
    final adMax = _applyMaskByAvg(adMax0, adAvg);

    String pick(String fallback, String? fromApi) {
      final t = fromApi?.trim();
      return (t != null && t.isNotEmpty) ? t : fallback;
    }

    return {
      AppTextStrings.clusterNegHigh: EmotionData(
        color: AppColors.negHigh,
        spots: _toSpotsConnected(nhAvg), // ★ null은 건너뛰므로 선이 이어짐
        avg: _avgScaledOpt(nhAvg), // ★ null 제외하고 평균
        min: _minScaledOpt(nhMin), // ★ null 제외하고 최솟값
        max: _maxScaledOpt(nhMax), // ★ null 제외하고 최댓값
        description: pick(
          "스트레스가 쌓일 때는 마음이 무겁고 숨이 답답해지죠...",
          s?.negHighSummary,
        ),
      ),
      AppTextStrings.clusterNegLow: EmotionData(
        color: AppColors.negLow,
        spots: _toSpotsConnected(nlAvg),
        avg: _avgScaledOpt(nlAvg),
        min: _minScaledOpt(nlMin),
        max: _maxScaledOpt(nlMax),
        description: pick(
          "지쳤다는 신호가 보여요...",
          s?.negLowSummary,
        ),
      ),
      AppTextStrings.clusterPositive: EmotionData(
        color: AppColors.positive,
        spots: _toSpotsConnected(posAvg),
        avg: _avgScaledOpt(posAvg),
        min: _minScaledOpt(posMin),
        max: _maxScaledOpt(posMax),
        description: pick(
          "평온함을 느끼고 있다면...",
          s?.positiveSummary,
        ),
      ),
      AppTextStrings.clusterSleep: EmotionData(
        color: AppColors.sleep,
        spots: _toSpotsConnected(slAvg),
        avg: _avgScaledOpt(slAvg),
        min: _minScaledOpt(slMin),
        max: _maxScaledOpt(slMax),
        description: pick(
          "잠이 오지 않거나...",
          s?.sleepSummary,
        ),
      ),
      AppTextStrings.clusterAdhd: EmotionData(
        color: AppColors.adhd,
        spots: _toSpotsConnected(adAvg),
        avg: _avgScaledOpt(adAvg),
        min: _minScaledOpt(adMin),
        max: _maxScaledOpt(adMax),
        description: pick(
          "집중이 흩어지고 마음이 산만할 때가 있죠...",
          s?.adhdSummary,
        ),
      ),
    };
  }
}

/// ----- Provider (ViewModel) -----
final clusterScoresViewModelProvider =
    StateNotifierProvider<ClusterScoresViewModel, ClusterScoresState>((ref) {
  final chart14Data = ref.watch(get14DayClusterStatsUseCaseProvider);
  return ClusterScoresViewModel(chart14Data);
});
