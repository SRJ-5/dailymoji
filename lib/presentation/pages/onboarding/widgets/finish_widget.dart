import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FinishWidget extends StatelessWidget {
  final String text;
  const FinishWidget({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 566.h,
      child: Column(
        children: [
          SizedBox(height: 90.h),
          SizedBox(
            width: double.infinity,
            height: 94.h,
            child: Center(
                child: AppText(
              textAlign: TextAlign.center,
              text,
              style: AppFontStyles.heading2
                  .copyWith(color: AppColors.grey900),
            )),
          ),
          Image.asset(
            AppImages.cadoLove,
            width: 180.w,
            height: 270.h,
          )
        ],
      ),
    );
  }
}
