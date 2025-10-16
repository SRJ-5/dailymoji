import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportTutorial extends StatelessWidget {
  final int step; // 0: 모지 달력, 1: 모지 차트
  final VoidCallback onClose;

  const ReportTutorial({
    super.key,
    required this.step,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: step == 0 ? _calendarTutorial(context) : _chartTutorial(context),
    );
  }

  Widget _calendarTutorial(BuildContext context) {
    return Stack(children: [
      Image.asset(
        AppImages.montlyTutorial,
        fit: BoxFit.fill,
      ),
      _okButton(onPressed: onClose, page: "monthly"),
    ]);
  }

  Widget _chartTutorial(BuildContext context) {
    return Stack(children: [
      Image.asset(
        AppImages.weeklyTutorial,
        fit: BoxFit.fill,
      ),
      _okButton(onPressed: onClose, page: "weekly"),
    ]);
  }
}

Widget _okButton({required VoidCallback onPressed, required String page}) {
  return Positioned(
    bottom: page == "monthly" ? 140.h : 385.h,
    left: 0.w,
    right: 0.w,
    child: Center(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green500,
          padding: EdgeInsets.symmetric(horizontal: 46.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          AppTextStrings.confirmButton,
          style: AppFontStyles.bodyMedium16.copyWith(color: AppColors.grey50),
        ),
      ),
    ),
  );
}
