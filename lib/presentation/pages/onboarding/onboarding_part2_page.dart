import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/finish_widget.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part2/test_widget.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/top_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class OnboardingPart2Page extends ConsumerStatefulWidget {
  @override
  ConsumerState<OnboardingPart2Page> createState() =>
      _OnboardingPart2PageState();
}

class _OnboardingPart2PageState
    extends ConsumerState<OnboardingPart2Page> {
  final onBoardingQuestion = AppTextStrings.onboardingQuestions;

  int stepIndex = 0;
  late int totalSteps = onBoardingQuestion.length;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userViewModelProvider);
    final isNextEnabled =
        state.step2Answers[stepIndex] == -1 ? false : true;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        leading: stepIndex > 0 && stepIndex != totalSteps
            ? IconButton(
                onPressed: () {
                  setState(() => stepIndex--);
                },
                icon: Icon(Icons.arrow_back))
            : null,
        title: stepIndex == totalSteps
            ? null
            : AppText(
                '현재 ${state.userProfile!.userNickNm}의 감정 기록',
                style: AppFontStyles.bodyBold18
                    .copyWith(color: AppColors.grey900),
              ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            stepIndex == totalSteps
                ? SizedBox.shrink()
                : TopIndicator(
                    width: 28,
                    totalSteps: totalSteps - 1,
                    stepIndex: stepIndex), // indicator 맨 위
            Expanded(
                child: stepIndex == totalSteps
                    ? FinishWidget(
                        text: '모든 준비 완료!\n함께 시작해 볼까요?',
                      )
                    : TestWidget(
                        key: ValueKey(stepIndex),
                        text: onBoardingQuestion[stepIndex],
                        questionIndex: stepIndex,
                      )),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          width: 100.w,
          height: 100.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            // .copyWith(top: 5.h),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 52.h),
                    backgroundColor: isNextEnabled
                        ? AppColors.green500
                        : AppColors.grey200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: isNextEnabled
                      ? () {
                          if (stepIndex < totalSteps) {
                            setState(() {
                              // isNextEnabled = false;
                              stepIndex++;
                            });
                          } else if (stepIndex == totalSteps) {
                            // ViewModel의 state를 직접 넘기지 않고, ViewModel 내부 함수를 호출
                            ref
                                .read(userViewModelProvider
                                    .notifier)
                                .fetchInsertUser();
                            context.go('/home');
                          }
                        }
                      : null,
                  child: AppText(
                      stepIndex == totalSteps ? '시작하기' : '계속하기',
                      style: AppFontStyles.bodyMedium16.copyWith(
                        color: isNextEnabled
                            ? AppColors.grey50
                            : AppColors.grey500,
                      )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
