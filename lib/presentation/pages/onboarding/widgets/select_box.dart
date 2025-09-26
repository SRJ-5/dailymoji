import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectBox extends StatelessWidget {
  const SelectBox({
    super.key,
    required this.isSelected,
    required this.text,
  });

  final bool isSelected;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48.h,
      padding:
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
          color: isSelected
              ? AppColors.green500
              : AppColors.green50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              width: isSelected ? 2 : 1,
              color: isSelected
                  ? AppColors.green200
                  : AppColors.grey200)),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: AppFontStyles.bodyMedium16.copyWith(
                color: isSelected
                    ? AppColors.grey50
                    : AppColors.grey900),
          )),
    );
  }
}
