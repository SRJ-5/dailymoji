import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TopIndicator extends StatelessWidget {
  const TopIndicator({
    super.key,
    required this.width,
    required this.totalSteps,
    required this.stepIndex,
  });

  final int width;
  final int totalSteps;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 28.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(totalSteps + 1, (index) {
          bool isActive = index <= stepIndex;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Container(
              width: width.w,
              height: 9.h,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.5.r),
                  color: isActive
                      ? Color(0xff778654)
                      : Color(0xffe8ebe0)),
            ),
          );
        }),
      ),
    );
  }
}
