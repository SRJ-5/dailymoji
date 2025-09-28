import 'package:dailymoji/presentation/pages/report/data/month_cluster_mapping.dart';
import 'package:dailymoji/presentation/providers/month_cluster_scores_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';
import 'package:flutter_riverpod/legacy.dart';

/// UI에 내보낼 상태
class ClusterMonthState {
  final List<ClusterScore> dailyMax; // 하루당 1건(오름차순)
  final Map<int, String> emojiByDay; // 1~31 -> asset path
  final int? selectedDay; // 옵션: 현재 선택된 날짜

  const ClusterMonthState({
    required this.dailyMax,
    required this.emojiByDay,
    this.selectedDay,
  });

  ClusterMonthState copyWith({
    List<ClusterScore>? dailyMax,
    Map<int, String>? emojiByDay,
    int? selectedDay,
  }) {
    return ClusterMonthState(
      dailyMax: dailyMax ?? this.dailyMax,
      emojiByDay: emojiByDay ?? this.emojiByDay,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }
}

/// 뷰모델: 월 데이터 로드 + 이모지 매핑 + 선택일 핸들링
class ClusterMonthViewModel
    extends StateNotifier<AsyncValue<ClusterMonthState>> {
  final Ref _ref;
  final MonthParams _params;

  ClusterMonthViewModel(this._ref, this._params)
      : super(const AsyncValue.loading());

  // 외부에서 호출: 최초 로드/리프레시
  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final uc = _ref.read(getMonthClusterScoresUseCaseProvider);
      final rows = await uc.execute(
        userId: _params.userId,
        year: _params.year,
        month: _params.month,
      );

      final emoji = buildEmojiMapByDay(rows);
      state = AsyncValue.data(
        ClusterMonthState(dailyMax: rows, emojiByDay: emoji),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 선택 일 변경(옵션)
  void selectDay(int? day) {
    final cur = state.asData?.value; // ← 여기!
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(selectedDay: day));
  }

// UI 헬퍼: 특정 일의 에셋 경로
  String? emojiPathForDay(int day) {
    final cur = state.asData?.value; // ← 여기!
    return cur?.emojiByDay[day];
  }

// UI 헬퍼: 특정 일의 ClusterScore
  ClusterScore? clusterForDay(int day) {
    final cur = state.asData?.value; // ← 여기!
    if (cur == null) return null;

    // firstWhere는 없으면 throw라 try/catch 또는 safe 추출
    for (final e in cur.dailyMax) {
      if (e.createdAt.toLocal().day == day) return e;
    }
    return null;
  }
}

final clusterMonthViewModelProvider = StateNotifierProvider.autoDispose
    .family<ClusterMonthViewModel, AsyncValue<ClusterMonthState>, MonthParams>(
  (ref, params) {
    final vm = ClusterMonthViewModel(ref, params);
    // 최초 로드
    vm.load();
    return vm;
  },
);
