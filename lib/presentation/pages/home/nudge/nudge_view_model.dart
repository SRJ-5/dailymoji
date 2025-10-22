// lib/presentation/pages/home/nudge/nudge_view_model.dart
import 'package:dailymoji/presentation/providers/get_last_survey_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailymoji/presentation/pages/home/nudge/nudge_storage.dart';
import 'package:dailymoji/domain/entities/assessment_last_survey.dart';
import 'package:dailymoji/domain/use_cases/get_last_survey_usecase.dart';

class NudgeState {
  final bool shouldShow;
  final AssessmentLastSurvey? last;
  const NudgeState({required this.shouldShow, this.last});
}

/// ✅ v3 노-코드젠 트릭:
/// - Provider에서 (String userId) => NudgeViewModel()..userId = userId
///   로 "필드 주입"을 하고
/// - 클래스는 AsyncNotifier<NudgeState>만 상속해서 build()에 인자 없이 접근
final nudgeViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<NudgeViewModel, NudgeState, String>(
  (String userId) => NudgeViewModel()..userId = userId,
);

class NudgeViewModel extends AsyncNotifier<NudgeState> {
  late final NudgeStorage _storage;

  // ✅ provider에서 주입되는 family 인자
  late String userId;

  @override
  Future<NudgeState> build() async {
    _storage = NudgeStorage();

    // 1) 스누즈 우선
    final snoozeUntil = await _storage.getSnoozeUntil();
    if (snoozeUntil != null &&
        DateTime.now().toUtc().isBefore(snoozeUntil.toUtc())) {
      return const NudgeState(shouldShow: false);
    }

    // 2) 최신 설문(Usecase 호출)
    final GetLastSurveyUsecase usecase = ref.read(getLastSurveyUsecaseProvider);
    final AssessmentLastSurvey? last = await usecase.execute(userId);

    // 3) 기록 없으면 → 유도
    if (last == null) {
      return const NudgeState(shouldShow: true, last: null);
    }

    // 4) 7일 경과 검사 (UTC)
    final nowUtc = DateTime.now().toUtc();
    final lastUtc = last.createdAt.toUtc();
    final diffDays = nowUtc.difference(lastUtc).inDays;

    return NudgeState(shouldShow: diffDays >= 7, last: last);
  }

  Future<void> snooze7Days() async {
    await _storage.snoozeDays(7);
    // 즉시 비표시 상태로 갱신
    state = const AsyncData(NudgeState(shouldShow: false));
  }
}
