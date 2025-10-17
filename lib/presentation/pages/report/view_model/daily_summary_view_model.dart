import 'package:dailymoji/domain/entities/daily_summary.dart';
import 'package:dailymoji/presentation/providers/daily_summary_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailySummaryState {
  final bool isLoading;
  final List<DailySummary> dailySummaries;
  final String? error;
  final DateTime? selectedDate;
  final String? selectedCluster;
  final String? summaryText;

  DailySummaryState({
    required this.isLoading,
    required this.dailySummaries,
    this.selectedDate,
    this.selectedCluster,
    this.summaryText,
    this.error,
  });

  factory DailySummaryState.initial() => DailySummaryState(
        isLoading: false,
        dailySummaries: const [],
      );

  DailySummaryState copyWith({
    bool? isLoading,
    List<DailySummary>? dailySummaries,
    String? error,
    DateTime? selectedDate,
    String? selectedCluster,
    String? summaryText,
  }) {
    return DailySummaryState(
      isLoading: isLoading ?? this.isLoading,
      dailySummaries: dailySummaries ?? this.dailySummaries,
      selectedDate: selectedDate,
      selectedCluster: selectedCluster,
      summaryText: summaryText,
      error: error,
    );
  }
}

/// ----- ViewModel -----
class DailySummaryViewModel extends Notifier<DailySummaryState> {
  @override
  DailySummaryState build() {
    return DailySummaryState.initial();
  }

  // ✅ [변경됨] 데이터를 가져오고 상태 갱신까지 수행하는 함수로 수정
  Future<void> fetchMonthData(String userId, DateTime focusedDate) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await ref.read(dailySummaryUsecaseProvider).execute(
            userId: userId,
            startInclusive: DateTime(focusedDate.year, focusedDate.month, 1),
            endExclusive: DateTime(focusedDate.year, focusedDate.month + 1, 1),
          );

      // 상태 갱신
      state = state.copyWith(
        isLoading: false,
        dailySummaries: results,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final dailySummaryViewModelProvider =
    NotifierProvider.autoDispose<DailySummaryViewModel, DailySummaryState>(
        DailySummaryViewModel.new);




















// /// ----- State -----
// class ClusterScoresState {
//   final bool isLoading;
//   final List<DailySummary> scores; // 오늘 데이터(기존)
//   final String? error;

//   // 차트용(14일 집계 결과 변환본)
//   final List<DateTime> days; // x축(오래된 → 최신)
//   final Map<String, EmotionData> emotionMap; // "불안/분노" 등 → EmotionData

//   final WeeklySummary? weeklySummary;

//   ClusterScoresState({
//     required this.isLoading,
//     required this.scores,
//     required this.days,
//     required this.emotionMap,
//     this.weeklySummary,
//     this.error,
//   });

//   factory ClusterScoresState.initial() => ClusterScoresState(
//         isLoading: false,
//         scores: const [],
//         days: const [],
//         emotionMap: const {},
//         weeklySummary: null,
//       );

//   ClusterScoresState copyWith({
//     bool? isLoading,
//     List<ClusterScore>? scores,
//     String? error,
//     List<DateTime>? days,
//     Map<String, EmotionData>? emotionMap,
//     WeeklySummary? weeklySummary,
//   }) {
//     return ClusterScoresState(
//       isLoading: isLoading ?? this.isLoading,
//       scores: scores ?? this.scores,
//       error: error,
//       days: days ?? this.days,
//       emotionMap: emotionMap ?? this.emotionMap,
//       weeklySummary: weeklySummary ?? this.weeklySummary,
//     );
//   }
// }

// /// ----- ViewModel -----
// class ClusterScoresViewModel extends StateNotifier<ClusterScoresState> {
//   final Get14DayClusterStatsUseCase _getAgg14UC;

//   ClusterScoresViewModel(this._getAgg14UC)
//       : super(ClusterScoresState.initial());




// /// ----- Provider (ViewModel) -----
// final clusterScoresViewModelProvider =
//     StateNotifierProvider<ClusterScoresViewModel, ClusterScoresState>((ref) {
//   final chart14Data = ref.watch(get14DayClusterStatsUseCaseProvider);
//   return ClusterScoresViewModel(chart14Data);
// });