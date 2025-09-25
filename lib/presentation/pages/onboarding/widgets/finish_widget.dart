import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FinishWidget extends StatelessWidget {
  final String text;
  const FinishWidget({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 90.h),
        SizedBox(
          width: double.infinity,
          height: 94.h,
          child: Center(
              child: Text(
            textAlign: TextAlign.center,
            text,
            style: AppFontStyles.heading2
                .copyWith(color: AppColors.grey900),
          )),
        ),
        Image.asset(
          'assets/images/cado_love.png',
          width: 180.w,
          height: 270.h,
        )
      ],
    );
  }
}
