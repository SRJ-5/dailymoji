import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/onboarding_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part2/test_widget.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/top_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPart2Page extends ConsumerStatefulWidget {
  @override
  ConsumerState<OnboardingPart2Page> createState() =>
      _OnboardingPart2PageState();
}

class _OnboardingPart2PageState
    extends ConsumerState<OnboardingPart2Page> {
  final personalities = [
    '지난 2주 동안, 기분이 가라앉거나, 우울했거나, 절망적이었나요?',
    '지난 2주 동안, 일에 흥미를 잃거나 즐거움을 느끼지 못했나요?',
    '지난 2주 동안, 초조하거나 긴장되거나 불안감을 자주 느꼈나요?',
    '지난 2주 동안, 걱정을 멈추거나 조절하기 어려웠나요?',
    '지난 한 달 동안, 통제할 수 없거나 예상치 못한 일 때문에 화가 나거나 속상한 적이 있었나요?',
    '지난 한 달 동안, 잠들기 어렵거나 자주 깨는 문제가 얼마나 있었나요?',
    '전반적으로, 나는 내 자신에 대해 긍정적인 태도를 가지고 있나요?',
    '직무/일상적인 과제 때문에 신체적, 정신적으로 지쳐있다고 느끼나요?',
    '자주 일상적인 일을 끝내는 것을 잊거나, 마무리 못하는 경우가 있나요?',
  ];

  int stepIndex = 0;
  late int totalSteps = personalities.length - 1;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final isNextEnabled = state.step2Answers[stepIndex]
        // switch (stepIndex) {
        //   0 => state.step2Answers[stepIndex],
        //   1 => state.step22,
        //   2 => state.step23,
        //   3 => state.step24,
        //   4 => state.step25,
        //   5 => state.step26,
        //   6 => state.step27,
        //   7 => state.step28,
        //   8 => state.step29,
        //   _ => false,
        // }
        ;
    return Scaffold(
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
        title: Text(
          '현재 ${state.userNickName}의 감정 기록',
          style: AppFontStyles.bodyBold18
              .copyWith(color: AppColors.grey900),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w)
            .copyWith(bottom: 20.h),
        child: Column(
          children: [
            TopIndicator(
                width: 28,
                totalSteps: totalSteps,
                stepIndex: stepIndex), // indicator 맨 위
            Expanded(
                child: TestWidget(
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
                    backgroundColor: isNextEnabled
                        ? AppColors.green400
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
                            // TODO: go router로 교체 해야함, 페이지 연결하고 진행
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      OnboardingPart2Page()),
                            );
                          }
                        }
                      : null,
                  child: Text(
                      stepIndex == totalSteps ? '완료' : '계속하기',
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
