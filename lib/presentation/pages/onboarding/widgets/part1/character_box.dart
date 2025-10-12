import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class character_box extends StatelessWidget {
  final double viewportFraction;
  character_box({super.key, required this.viewportFraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 288.w / viewportFraction,
      height: 440.h / viewportFraction,
      padding: EdgeInsets.symmetric(horizontal: 16.h)
          .copyWith(top: 36.h, bottom: 24.h),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 4),
              color: Color.fromRGBO(29, 41, 61, 0.1),
              blurRadius: 8,
              spreadRadius: -2,
            )
          ],
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(24.r),
          border:
              Border.all(width: 1, color: AppColors.grey200)),
      child: Column(
        children: [
          SizedBox(
            width: 241.w,
            height: 260.h,
            child: Image.asset(
              AppImages.cadoProfile,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 12.r),
          AppText(
            '차분하게 상황을 분석하고\n문제를 해결하는 친구',
            textAlign: TextAlign.center,
            style: AppFontStyles.bodySemiBold16
                .copyWith(color: AppColors.grey900),
          ),
          SizedBox(height: 20.r),
          GestureDetector(
            onTap: () {},
            child: Center(
              child: Container(
                width: 105.w,
                height: 40.h,
                padding: EdgeInsets.symmetric(vertical: 8.h)
                    .copyWith(left: 16.w, right: 10.w),
                decoration: BoxDecoration(
                  color: AppColors.green500,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Row(
                    children: [
                      AppText(
                        '선택하기',
                        style: AppFontStyles.bodyMedium14
                            .copyWith(color: AppColors.grey50),
                      ),
                      SizedBox(width: 10.8.r),
                      SvgPicture.asset(AppIcons.arrowForward,
                          width: 14.4.w,
                          height: 11.98.h,
                          colorFilter: ColorFilter.mode(
                              AppColors.grey50, BlendMode.srcIn))
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
