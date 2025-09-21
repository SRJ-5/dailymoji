import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/onboarding_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/AiNameSetting.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/SelectAi.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/SelectAiPersonality.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part2_page.dart';
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
  int totalSteps = 2;

  @override
  Widget build(BuildContext context) {
    final isNextEnabled = switch (stepIndex) {
      0 => ref.watch(onboardingViewModelProvider).step11,
      1 => ref.watch(onboardingViewModelProvider).step12,
      2 => ref.watch(onboardingViewModelProvider).step13,
      _ => false,
    };
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
            'Step 1. 캐릭터 설정',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20)
              .copyWith(bottom: 20),
          child: Column(
            children: [
              TopIndicator(
                  totalSteps: totalSteps,
                  stepIndex: stepIndex), // indicator 맨 위
              Expanded(
                child: [
                  SelectAi(),
                  AiNameSetting(),
                  SelectAiPersonality(),
                ][stepIndex],
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: SizedBox(
            width: 100,
            height: 100,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 52.h),
                      backgroundColor: isNextEnabled
                          ? AppColors.green400
                          : AppColors.grey200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                      '계속하기',
                      style: TextStyle(
                        color: isNextEnabled
                            ? AppColors.grey900
                            : AppColors.grey500,
                        fontSize: 16,
                      ),
                    ),
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

class TopIndicator extends StatelessWidget {
  const TopIndicator({
    super.key,
    required this.totalSteps,
    required this.stepIndex,
  });

  final int totalSteps;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 28.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(totalSteps + 1, (index) {
          bool isActive = index <= stepIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 51.w,
              height: 9.h,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.5.r),
                  color: isActive
                      ? Color(0xff778654)
                      : Color(0xffe8ebe0)),
            ),
          );
        }),
      ),
    );
  }
}
