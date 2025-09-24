import 'package:dailymoji/core/styles/colors.dart';
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

class _OnboardingPart2PageState extends ConsumerState<OnboardingPart2Page> {
  final personalities = [
    '지난 2주 동안, 기분이\n가라앉거나, 우울했거나,\n절망적이었나요?',
    '지난 2주 동안, 일에 흥미를 잃거나 즐거움을 느끼지 못했나요?',
    '지난 2주 동안, 초조하거나 긴장되거나 불안감을 자주 느꼈나요?',
    '지난 2주 동안,\n걱정을 멈추거나 조절하기 \n어려웠나요?',
    '최근 한 달, 통제할 수 없거나 예상치 못한 일 때문에 화가 나거나 속상했나요?',
    '지난 한 달 동안, 잠들기 \n어렵거나 자주 깨는 문제가 \n얼마나 있었나요?',
    '전반적으로, 나는 내 \n자신에 대해 긍정적인 \n태도를 가지고 있나요?',
    '직무/일상적인 과제 때문에 신체적, 정신적으로 지쳐 있다고 느끼나요?',
    '자주 일상적인 일을 끝내는 \n것을 잊거나, 마무리 \n못하는 경우가 있나요?',
  ];

  int stepIndex = 0;
  late int totalSteps = personalities.length;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userViewModelProvider);
    final isNextEnabled = state.step2Answers[stepIndex];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        leading: stepIndex > 0
            ? IconButton(
                onPressed: () {
                  setState(() => stepIndex--);
                },
                icon: Icon(Icons.arrow_back))
            : null,
        title: stepIndex == totalSteps
            ? null
            : Text(
                '현재 ${state.userProfile!.userNickNm}의 감정 기록',
                style:
                    AppFontStyles.bodyBold18.copyWith(color: AppColors.grey900),
              ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 20.h),
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
                        text: personalities[stepIndex],
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
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 52.h),
                    backgroundColor:
                        isNextEnabled ? AppColors.green400 : AppColors.grey200,
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
                                .read(userViewModelProvider.notifier)
                                .fetchInsertUser();
                            context.go('/home');
                          }
                        }
                      : null,
                  child: Text(stepIndex == totalSteps ? '시작하기' : '계속하기',
                      style: AppFontStyles.bodyMedium16.copyWith(
                        color: isNextEnabled
                            ? AppColors.grey900
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
