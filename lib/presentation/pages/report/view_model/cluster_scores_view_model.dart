import 'package:dailymoji/presentation/pages/report/weekly_report.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';
import 'package:dailymoji/domain/use_cases/cluster_use_case/get_today_cluster_scores_use_case.dart';
import 'package:dailymoji/domain/models/cluster_stats_models.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/providers/today_cluster_scores_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

/// ----- State -----
class ClusterScoresState {
  final bool isLoading;
  final List<ClusterScore> scores; // 오늘 데이터(기존)
  final String? error;

  // 차트용(14일 집계 결과 변환본)
  final List<DateTime> days; // x축(오래된 → 최신)
  final Map<String, EmotionData> emotionMap; // "불안/분노" 등 → EmotionData

  ClusterScoresState({
    required this.isLoading,
    required this.scores,
    required this.days,
    required this.emotionMap,
    this.error,
  });

  factory ClusterScoresState.initial() => ClusterScoresState(
        isLoading: false,
        scores: const [],
        days: const [],
        emotionMap: const {},
      );

  ClusterScoresState copyWith({
    bool? isLoading,
    List<ClusterScore>? scores,
    String? error,
    List<DateTime>? days,
    Map<String, EmotionData>? emotionMap,
  }) {
    return ClusterScoresState(
      isLoading: isLoading ?? this.isLoading,
      scores: scores ?? this.scores,
      error: error,
      days: days ?? this.days,
      emotionMap: emotionMap ?? this.emotionMap,
    );
  }
}

/// ----- ViewModel -----
class ClusterScoresViewModel extends StateNotifier<ClusterScoresState> {
  final GetTodayClusterScoresUseCase _getTodayUC;
  final Get14DayClusterStatsUseCase _getAgg14UC;

  ClusterScoresViewModel(this._getTodayUC, this._getAgg14UC)
      : super(ClusterScoresState.initial());

  /// 오늘 원본 리스트 로드 (기존 용도)
  Future<void> fetchTodayScores() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _getTodayUC.execute();
      state = state.copyWith(isLoading: false, scores: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 14일 집계 로드 → EmotionData로 변환(차트/카드 용도)
  Future<void> load14DayChart(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final agg = await _getAgg14UC.execute(userId: userId);
      final emap = _buildEmotionMap(agg);
      state =
          state.copyWith(isLoading: false, days: agg.days, emotionMap: emap);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
        if (e != null) e!
    ];
    if (vals.isEmpty) return 0.0;
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    return scaleToTen(avg);
  }

  double _minScaledOpt(List<double?> v) {
    final vals = [
      for (final e in v)
        if (e != null) e!
    ];
    if (vals.isEmpty) return 0.0;
    return scaleToTen(vals.reduce((a, b) => a < b ? a : b));
  }

  double _maxScaledOpt(List<double?> v) {
    final vals = [
      for (final e in v)
        if (e != null) e!
    ];
    if (vals.isEmpty) return 0.0;
    return scaleToTen(vals.reduce((a, b) => a > b ? a : b));
  }

  Map<String, EmotionData> _buildEmotionMap(FourteenDayAgg agg) {
    final nhAvg = agg.series[ClusterType.negHigh]![Metric.avg]!;
    final nhMin = agg.series[ClusterType.negHigh]![Metric.min]!;
    final nhMax = agg.series[ClusterType.negHigh]![Metric.max]!;

    final nlAvg = agg.series[ClusterType.negLow]![Metric.avg]!;
    final nlMin = agg.series[ClusterType.negLow]![Metric.min]!;
    final nlMax = agg.series[ClusterType.negLow]![Metric.max]!;

    final posAvg = agg.series[ClusterType.positive]![Metric.avg]!;
    final posMin = agg.series[ClusterType.positive]![Metric.min]!;
    final posMax = agg.series[ClusterType.positive]![Metric.max]!;

    final slAvg = agg.series[ClusterType.sleep]![Metric.avg]!;
    final slMin = agg.series[ClusterType.sleep]![Metric.min]!;
    final slMax = agg.series[ClusterType.sleep]![Metric.max]!;

    final adAvg = agg.series[ClusterType.adhd]![Metric.avg]!;
    final adMin = agg.series[ClusterType.adhd]![Metric.min]!;
    final adMax = agg.series[ClusterType.adhd]![Metric.max]!;

    return {
      "불안/분노": EmotionData(
        color: AppColors.negHigh,
        spots: _toSpotsConnected(nhAvg), // 보통 평균 시퀀스로 라인 차트
        avg: _avgScaledOpt(nhAvg), // 기간 전체 평균
        min: _minScaledOpt(nhMin), // 기간 내 최저
        max: _maxScaledOpt(nhMax), // 기간 내 최고
        description: "스트레스 지수가 연속 3일간 상승했어요. 잠깐 호흡하면서 리셋해요.",
      ),
      "우울/무기력/번아웃": EmotionData(
        color: AppColors.negLow,
        spots: _toSpotsConnected(nlAvg),
        avg: _avgScaledOpt(nlAvg),
        min: _minScaledOpt(nlMin),
        max: _maxScaledOpt(nlMax),
        description: "지쳤다는 신호가 보여요. 잠시 쉬어가세요.",
      ),
      "평온/회복": EmotionData(
        color: AppColors.positive,
        spots: _toSpotsConnected(posAvg),
        avg: _avgScaledOpt(posAvg),
        min: _minScaledOpt(posMin),
        max: _maxScaledOpt(posMax),
        description: "안정적인 감정 상태가 유지되고 있어요.",
      ),
      "불면/과다수면": EmotionData(
        color: AppColors.sleep,
        spots: _toSpotsConnected(slAvg),
        avg: _avgScaledOpt(slAvg),
        min: _minScaledOpt(slMin),
        max: _maxScaledOpt(slMax),
        description: "수면 패턴을 점검해볼까요?",
      ),
      "ADHD": EmotionData(
        color: AppColors.adhd,
        spots: _toSpotsConnected(adAvg),
        avg: _avgScaledOpt(adAvg),
        min: _minScaledOpt(adMin),
        max: _maxScaledOpt(adMax),
        description: "집중 리듬을 일정하게 잡아봐요.",
      ),
    };
  }
}

/// ----- Provider (ViewModel) -----
final clusterScoresViewModelProvider =
    StateNotifierProvider<ClusterScoresViewModel, ClusterScoresState>((ref) {
  final todayUC = ref.watch(getTodayClusterScoresUseCaseProvider);
  final agg14UC = ref.watch(get14DayClusterStatsUseCaseProvider);
  return ClusterScoresViewModel(todayUC, agg14UC);
});
