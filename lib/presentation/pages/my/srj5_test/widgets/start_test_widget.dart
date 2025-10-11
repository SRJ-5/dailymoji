import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StartTestWidget extends StatelessWidget {
  const StartTestWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50.h),
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
    );
  }
}
