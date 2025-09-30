import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/breathing_solution/solution_context_view_model.dart';
import 'package:dailymoji/presentation/pages/chat/chat_view_model.dart';
import 'package:dailymoji/presentation/pages/home/home_page.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/report/view_model/cluster_month_view_model.dart';
import 'package:dailymoji/presentation/pages/report/view_model/cluster_scores_view_model.dart';
import 'package:dailymoji/presentation/pages/report/weekly_report.dart';
import 'package:dailymoji/presentation/providers/month_cluster_scores_provider.dart';
import 'package:dailymoji/presentation/providers/solution_context_providers.dart';
import 'package:dailymoji/presentation/providers/today_cluster_scores_provider.dart';
import 'package:dailymoji/presentation/providers/user_providers.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

void resetAppState(WidgetRef ref) {
  ref.invalidate(selectedEmotionProvider);
  ref.invalidate(filterProvider);
  ref.invalidate(bottomNavIndexProvider);
  ref.invalidate(appleLoginUseCaseProvider);
  ref.invalidate(insertUserProfileUseCaseProvider);
  ref.invalidate(getUserProfileUseCaseProvider);
  ref.invalidate(updateUserNickNameUseCaseProvider);
  ref.invalidate(updateCharacterNameUseCaseProvider);
  ref.invalidate(updateCharacterPersonalityUseCaseProvider);
  ref.invalidate(clusterScoresDataSourceProvider);
  ref.invalidate(clusterScoresRepositoryProvider);
  ref.invalidate(getTodayClusterScoresUseCaseProvider);
  ref.invalidate(todayClusterScoresProvider);
  ref.invalidate(get14DayClusterStatsUseCaseProvider);
  ref.invalidate(fourteenDayAggProvider);
  ref.invalidate(getSolutionContextUseCaseProvider);
  ref.invalidate(getMonthClusterScoresUseCaseProvider);
  ref.invalidate(dailyMaxByMonthProvider);
  ref.invalidate(clusterMonthViewModelProvider);
  ref.invalidate(clusterScoresViewModelProvider);
  ref.invalidate(chatViewModelProvider);
  ref.invalidate(solutionContextViewModelProvider);
  ref.invalidate(userViewModelProvider);
  // 필요한 provider들 전부 여기에 나열
}

class ConfirmDialog extends ConsumerWidget {
  final bool isDeleteAccount;
  ConfirmDialog({
    super.key,
    required this.isDeleteAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileVM =
        ref.read(userViewModelProvider.notifier);
    // 배경 터치는 닫기, 다이얼로그 영역은 차단
    return GestureDetector(
      onTap: () => context.pop(), // 배경 터치시 다이얼로그 닫기
      child: Material(
        color:
            AppColors.black.withValues(alpha: 0.35), // 배경 오버레이
        child: Center(
          child: GestureDetector(
            // 다이얼로그 컨테이너 터치시 이벤트 차단 (배경 터치 이벤트가 전파되지 않음)
            onTap: () {},
            child: Container(
              width: 320.w, // 디자인 요구사항 그대로
              height: 186.h,
              padding: EdgeInsets.symmetric(horizontal: 34.w)
                  .copyWith(bottom: 24.h, top: 48.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isDeleteAccount
                        ? "정말 탈퇴하시겠어요?"
                        : "로그아웃 하시겠어요?",
                    style: AppFontStyles.heading3
                        .copyWith(color: AppColors.grey900),
                  ),
                  SizedBox(height: 36.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          print("취소 버튼 클릭");
                          context.pop();
                        },
                        child: Container(
                          width: 120.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.green50,
                            borderRadius:
                                BorderRadius.circular(12.r),
                            border: Border.all(
                                width: 1,
                                color: AppColors.grey200),
                          ),
                          child: Center(
                            child: Text(
                              '취소',
                              style: AppFontStyles.bodyMedium16
                                  .copyWith(
                                      color: AppColors.grey900),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      GestureDetector(
                        onTap: () async {
                          if (isDeleteAccount) {
                            // 계정 삭제
                            print('계정 탈퇴!!!!!');
                            await userProfileVM.deleteAccount();
                          } else {
                            print('로그아웃!!!!');
                            await userProfileVM.logOut();
                          }
                          print('상태태태태 초기화');
                          context.go('/login');
                          resetAppState(ref);
                          // 화면 이동 (GoRouter 사용시)
                        },
                        child: Container(
                          width: 120.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: isDeleteAccount
                                ? AppColors.noti900
                                : AppColors.green400,
                            borderRadius:
                                BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              '확인',
                              style: AppFontStyles.bodyMedium16
                                  .copyWith(
                                      color: isDeleteAccount
                                          ? AppColors.grey50
                                          : AppColors.grey900),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
