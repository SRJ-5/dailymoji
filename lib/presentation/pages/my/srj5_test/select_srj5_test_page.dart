import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/domain/entities/emotion_cluster.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/widgets/srj5_test_box.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/finish_widget.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part2/test_widget.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/top_indicator.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SelectSrj5TestPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<SelectSrj5TestPage> createState() =>
      _SelectSrj5TestPageState();
}

class _SelectSrj5TestPageState
    extends ConsumerState<SelectSrj5TestPage> {
  final clusters = EmotionClusters;

  int stepIndex = 0;
  late int totalSteps = 1;
  @override
  Widget build(BuildContext context) {
    final user = ref.read(userViewModelProvider);
    final userName = user.userProfile!.userNickNm;
    final isNextEnabled = true;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        actions: [
          GestureDetector(
              onTap: () {
                context.pop();
              },
              child: Icon(Icons.clear))
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: 40.h),
              AppText(
                '지금 $userName님께 필요한\n감정 검사를 선택해 볼까요?',
                textAlign: TextAlign.center,
                style: AppFontStyles.heading2
                    .copyWith(color: AppColors.grey900),
              ),
              SizedBox(height: 4.h),
              AppText(
                '각 검사는 약 2분 정도 소요돼요 🌱',
                textAlign: TextAlign.center,
                style: AppFontStyles.bodyRegular14
                    .copyWith(color: AppColors.grey700),
              ),
              Expanded(
                  child: Column(
                children: [
                  SizedBox(
                      width: 237.67.w,
                      height: 255.h,
                      child: Image.asset(
                        AppImages.cadoTest,
                        fit: BoxFit.cover,
                      )),
                  SizedBox(height: 50.h),
                  AppText(
                    '총 9문항 ∙ 약 2분 소요',
                    style: AppFontStyles.bodySemiBold18
                        .copyWith(color: AppColors.grey900),
                  )
                ],
              )
                  // child: stepIndex == totalSteps
                  //     ? FinishWidget(
                  //         text: '모든 준비 완료!\n함께 시작해 볼까요?',
                  //       )
                  //     : Srj5TestBox(
                  //         key: ValueKey(stepIndex),
                  //         text: personalities[stepIndex],
                  //         questionIndex: stepIndex,
                  //       )
                  ),
            ],
          ),
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
                            //     .read().;
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
