import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GuideWidgetBox extends StatelessWidget {
  final int guideIndex;
  GuideWidgetBox({
    super.key,
    required this.guideIndex,
  });

  final List<String> guideImages = [
    AppImages.cadoRecord,
    AppImages.carrotChat,
    AppImages.cadoCalender
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
            textAlign: TextAlign.center,
            textScaler: TextScaler.noScaling,
            text: TextSpan(
                text: AppTextStrings.startGuideText[guideIndex],
                style: AppFontStyles.heading2
                    .copyWith(color: AppColors.grey900),
                children: <TextSpan>[
                  TextSpan(
                      text: AppTextStrings
                          .middleGuideText[guideIndex],
                      style: AppFontStyles.heading2
                          .copyWith(color: AppColors.green500)),
                  TextSpan(
                      text: AppTextStrings
                          .endGuideText[guideIndex])
                ])),
        SizedBox(height: 46.h),
        SizedBox(
          width: 280.w,
          height: 300.h,
          child: Image.asset(
            guideImages[guideIndex],
            fit: BoxFit.cover,
          ),
        )
      ],
    );
  }
}
