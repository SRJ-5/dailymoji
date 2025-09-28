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
        description:
            "스트레스가 쌓일 때는 마음이 무겁고 숨이 답답해지죠. 하지만 모든 걸 혼자 짊어질 필요는 없습니다. 잠시 내려놓고 숨을 고르며 작은 쉼을 허락하세요. 당신은 이미 충분히 잘해내고 있어요.",
      ),
      "우울/무기력/번아웃": EmotionData(
        color: AppColors.negLow,
        spots: _toSpotsConnected(nlAvg),
        avg: _avgScaledOpt(nlAvg),
        min: _minScaledOpt(nlMin),
        max: _maxScaledOpt(nlMax),
        description:
            "지쳤다는 신호가 보여요. 완벽하지 않아도 괜찮습니다. 잠시 멈춰서 쉬어가는 것 또한 중요한 과정이에요. 자신을 위한 작은 여유를 챙겨 보세요.",
      ),
      "평온/회복": EmotionData(
        color: AppColors.positive,
        spots: _toSpotsConnected(posAvg),
        avg: _avgScaledOpt(posAvg),
        min: _minScaledOpt(posMin),
        max: _maxScaledOpt(posMax),
        description:
            "평온함을 느끼고 있다면, 그건 당신이 잘 버텨온 증거예요. 회복의 순간은 스스로에게 주는 가장 큰 선물이에요. 이 시간을 충분히 누리며 마음 깊이 새겨두세요. 앞으로 걸어갈 힘이 되어줄 거예요.",
      ),
      "불면/과다수면": EmotionData(
        color: AppColors.sleep,
        spots: _toSpotsConnected(slAvg),
        avg: _avgScaledOpt(slAvg),
        min: _minScaledOpt(slMin),
        max: _maxScaledOpt(slMax),
        description:
            "잠이 오지 않거나, 반대로 너무 많이 잘 때도 있어요. 그건 몸과 마음이 회복을 필요로 한다는 신호일 뿐이에요. 억지로 조절하려 하지 말고, 오늘은 있는 그대로를 받아들여 주세요. 조금씩 균형은 찾아올 거예요.",
      ),
      "ADHD": EmotionData(
        color: AppColors.adhd,
        spots: _toSpotsConnected(adAvg),
        avg: _avgScaledOpt(adAvg),
        min: _minScaledOpt(adMin),
        max: _maxScaledOpt(adMax),
        description:
            "집중이 흩어지고 마음이 산만할 때가 있죠. 완벽하지 않아도 괜찮습니다. 오늘은 작은 일 하나만 해내도 충분히 잘한 거예요. 자신을 탓하지 말고, 천천히 걸어가도 된다는 걸 기억하세요.",
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
