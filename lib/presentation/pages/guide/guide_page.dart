import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/guide/widgets/guide_indicator.dart';
import 'package:dailymoji/presentation/pages/guide/widgets/guide_widget_box.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class GuidePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends ConsumerState<GuidePage> {
  int stepIndex = 0;
  int totalSteps = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            SizedBox(height: 144.h),
            SizedBox(
              width: double.infinity,
              child: GuideWidgetBox(
                key: ValueKey(stepIndex),
                guideIndex: stepIndex,
              ),
            ),
            SizedBox(height: 40.h),
            GuideIndicator(
                totalSteps: totalSteps, stepIndex: stepIndex),
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
                    backgroundColor: AppColors.green500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () {
                    if (stepIndex < totalSteps) {
                      setState(() {
                        // isNextEnabled = false;
                        stepIndex++;
                      });
                    } else if (stepIndex == totalSteps) {
                      // ViewModel의 state를 직접 넘기지 않고, ViewModel 내부 함수를 호출
                      // ref
                      //     .read(userViewModelProvider.notifier)
                      //     .fetchInsertUser();
                      context.go('/login');
                    }
                  },
                  child: AppText(
                      stepIndex == totalSteps ? '시작하기' : '다음으로',
                      style: AppFontStyles.bodyMedium16.copyWith(
                        color: AppColors.grey50,
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
