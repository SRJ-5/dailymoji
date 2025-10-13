import 'package:dailymoji/core/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GuideIndicator extends StatelessWidget {
  const GuideIndicator({
    super.key,
    required this.totalSteps,
    required this.stepIndex,
  });

  final int totalSteps;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(totalSteps + 1, (index) {
          bool isActive = index <= stepIndex;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.5.r),
                  color: isActive
                      ? AppColors.grey900
                      : AppColors.grey100),
            ),
          );
        }),
      ),
    );
  }
}
