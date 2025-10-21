import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class NetworkErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              textAlign: TextAlign.center,
              AppTextStrings.networkErrorText1,
              style: AppFontStyles.bodyBold18
                  .copyWith(color: AppColors.grey900),
            ),
            SizedBox(height: 8.h),
            AppText(
              textAlign: TextAlign.center,
              AppTextStrings.networkErrorText2,
              style: AppFontStyles.bodyRegular14
                  .copyWith(color: AppColors.grey900),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () {
                context.go('/');
              },
              child: Container(
                height: 40.h,
                width: 109.w,
                decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                        width: 1, color: AppColors.grey200)),
                child: Center(
                  child: AppText(
                      AppTextStrings.tryReconnectingNetwork,
                      style: AppFontStyles.bodyMedium14
                          .copyWith(color: AppColors.grey900)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
