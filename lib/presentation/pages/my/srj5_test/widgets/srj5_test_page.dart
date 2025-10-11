import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/assessment_view_model.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/widgets/srj5_test_box.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/finish_widget.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/top_indicator.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class Srj5TestPage extends ConsumerStatefulWidget {
  Srj5TestPage({super.key});

  @override
  ConsumerState<Srj5TestPage> createState() =>
      _Srj5TestPageState();
}

class _Srj5TestPageState extends ConsumerState<Srj5TestPage> {
  int stepIndex = 0;
  late int totalSteps;

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userViewModelProvider).userProfile!;
    final testState = ref.watch(assessmentViewModelProvider);
    final clusterState = testState.questionsList!;
    final questionList = clusterState.questionText;
    totalSteps = questionList.length;
    final isNextEnabled =
        testState.questionScores?[stepIndex] == -1
            ? false
            : true;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        leading: GestureDetector(
          onTap: stepIndex == 0
              ? null
              : () {
                  setState(() => stepIndex--);
                },
          child: stepIndex == 0 ? null : Icon(Icons.arrow_back),
        ),
        title: stepIndex == totalSteps
            ? null
            : AppText(
                '${clusterState.clusterNM!} 감정 검사',
                style: AppFontStyles.bodyBold18
                    .copyWith(color: AppColors.grey900),
              ),
        centerTitle: true,
        actions: [
          GestureDetector(
              onTap: () {
                context.pop();
                context.pop();
              },
              child: Icon(
                Icons.clear,
                size: 24.r,
              )),
          SizedBox(width: 12.h)
        ],
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
                        text:
                            '좋아요!\n${user.userNickNm}님을 좀 더 이해하게 됐어요',
                        srj5: true,
                      )
                    : Srj5TestBox(
                        key: ValueKey(stepIndex),
                        text: questionList[stepIndex],
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
                            // ref
                            //     .read(assessmentViewModelProvider.notifier).;
                            context.go('/home');
                          }
                        }
                      : null,
                  child: AppText(
                      stepIndex == totalSteps ? '완료' : '다음으로',
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
