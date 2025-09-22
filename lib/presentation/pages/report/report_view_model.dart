import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/domain/entities/report_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. State 클래스
class ReportState {
  final bool isLoading;
  final String? errorMessage;
  final Map<DateTime, List<ReportRecord>> monthlyRecords; // 월별 데이터 저장
  final DateTime focusedMonth; // 현재 보고 있는 월

  ReportState({
    this.isLoading = true,
    this.errorMessage,
    this.monthlyRecords = const {},
    required this.focusedMonth,
  });

  ReportState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<DateTime, List<ReportRecord>>? monthlyRecords,
    DateTime? focusedMonth,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      monthlyRecords: monthlyRecords ?? this.monthlyRecords,
      focusedMonth: focusedMonth ?? this.focusedMonth,
    );
  }
}

// 2. Notifier (ViewModel)
class ReportViewModel extends Notifier<ReportState> {
  // TODO: 실제 사용자 ID로 교체
  final String _userId = "8dfc1a65-1fae-47f6-81f4-37257acc3db6";

  @override
  ReportState build() {
    final now = DateTime.now();
    final initialMonth = DateTime(now.year, now.month);
    // 뷰모델이 생성될 때 현재 달의 데이터를 가져옴
    Future(() => fetchRecordsForMonth(initialMonth));
    return ReportState(focusedMonth: initialMonth);
  }

  // 특정 달의 데이터를 가져오는 함수
  Future<void> fetchRecordsForMonth(DateTime month) async {
    // 이미 데이터가 있으면 다시 로드하지 않음
    if (state.monthlyRecords.containsKey(month)) {
      state = state.copyWith(focusedMonth: month);
      return;
    }

    state = state.copyWith(isLoading: true, focusedMonth: month);
    try {
      final repo = ref.read(reportRepositoryProvider);
      final records = await repo.getRecordsForMonth(_userId, month);

      // 날짜별로 그룹핑
      final Map<DateTime, List<ReportRecord>> dailyRecords = {};
      for (var record in records) {
        final dateKey =
            DateTime(record.date.year, record.date.month, record.date.day);
        if (dailyRecords[dateKey] == null) {
          dailyRecords[dateKey] = [];
        }
        dailyRecords[dateKey]!.add(record);
      }

      final updatedMonthlyRecords =
          Map<DateTime, List<ReportRecord>>.from(state.monthlyRecords);
      updatedMonthlyRecords[month] = records; // 월 단위 원본 데이터 저장

      state = state.copyWith(
        isLoading: false,
        monthlyRecords: updatedMonthlyRecords,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// 3. Provider
final reportViewModelProvider = NotifierProvider<ReportViewModel, ReportState>(
  () => ReportViewModel(),
);
