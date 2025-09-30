import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w)
          .copyWith(top: 48.h, bottom: 24.h),
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r)),
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("로그아웃 하시겠어요?",
                style: AppFontStyles.heading3
                    .copyWith(color: AppColors.grey900)),
            SizedBox(height: 36.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 120.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                        color: AppColors.green50,
                        borderRadius:
                            BorderRadius.circular(12.r),
                        border: Border.all(
                            width: 1, color: AppColors.grey200)),
                    child: TextButton(
                        onPressed: () {},
                        child: Text(
                          '취소',
                          style: AppFontStyles.bodyMedium16
                              .copyWith(
                                  color: AppColors.grey900),
                        ))),
                SizedBox(width: 12.w),
                Container(
                    width: 120.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                        color: AppColors.green400,
                        borderRadius:
                            BorderRadius.circular(12.r)),
                    child: TextButton(
                        onPressed: () {},
                        child: Text('확인',
                            style: AppFontStyles.bodyMedium16
                                .copyWith(
                                    color: AppColors.grey900)))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
