import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/onboarding_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/ai_name_setting.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/select_ai.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/select_ai_personality.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part2_page.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/top_indicator.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/user_nick_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPart1Page extends ConsumerStatefulWidget {
  @override
  ConsumerState<OnboardingPart1Page> createState() =>
      _OnboardingPart1PageState();
}

class _OnboardingPart1PageState
    extends ConsumerState<OnboardingPart1Page> {
  int stepIndex = 0;
  int totalSteps = 3;

  @override
  Widget build(BuildContext context) {
    final isNextEnabled = switch (stepIndex) {
      0 => ref.watch(onboardingViewModelProvider).step11,
      1 => ref.watch(onboardingViewModelProvider).step12,
      2 => ref.watch(onboardingViewModelProvider).step13,
      3 => ref.watch(onboardingViewModelProvider).step14,
      _ => false,
    };
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
            stepIndex == 3
                ? 'Step 1. 나의 닉네임 설정'
                : 'Step 1. 캐릭터 설정',
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
                  width: 51,
                  totalSteps: totalSteps,
                  stepIndex: stepIndex), // indicator 맨 위
              Expanded(
                child: [
                  SelectAi(),
                  AiNameSetting(),
                  SelectAiPersonality(),
                  UserNickName(),
                ][stepIndex],
              ),
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
                        borderRadius:
                            BorderRadius.circular(12.r),
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
                    child: Text('계속하기',
                        style:
                            AppFontStyles.bodyMedium16.copyWith(
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
      ),
    );
  }
}
