import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/assessment_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StartTestWidget extends ConsumerWidget {
  const StartTestWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late int testTime;
    final questionList = ref
        .read(assessmentViewModelProvider)
        .questionsList!
        .questionText;
    final questionLengh = questionList.length;
    questionLengh > 6 ? testTime = 3 : testTime = 2;

    return Column(
      children: [
        SizedBox(height: 50.h),
        SizedBox(
            width: 200.w,
            height: 209.h,
            child: Image.asset(
              AppImages.srj5TestStart,
              fit: BoxFit.cover,
            )),
        SizedBox(height: 50.h),
        AppText(
          '총 $questionLengh문항 ∙ 약 $testTime분 소요',
          style: AppFontStyles.bodySemiBold18
              .copyWith(color: AppColors.grey900),
        )
      ],
    );
  }
}
