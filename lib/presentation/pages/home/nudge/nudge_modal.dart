// lib/presentation/nudge/nudge_modal.dart

import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NudgeModal extends StatelessWidget {
  final VoidCallback onGo;
  final VoidCallback onSnooze7d;

  const NudgeModal({super.key, required this.onGo, required this.onSnooze7d});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onGo,
    required VoidCallback onSnooze7d,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NudgeModal(onGo: onGo, onSnooze7d: onSnooze7d),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: safeBottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(0.15))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppImages.glasses,
              width: 100.w,
              height: 108.h,
            ),
            SizedBox(height: 28.h),
            Text(AppTextStrings.checkYourEmotion,
                textAlign: TextAlign.center,
                style:
                    AppFontStyles.heading3.copyWith(color: AppColors.grey900)),
            SizedBox(height: 28.h),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onGo();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                width: double.infinity,
                height: 52.h,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: AppColors.green500),
                child: Center(
                  child: Text(
                    AppTextStrings.findMyEmotion,
                    style: AppFontStyles.bodyMedium16
                        .copyWith(color: AppColors.grey50),
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    onSnooze7d(); // 내부에서 스누즈 저장
                    Navigator.of(context).pop();
                  },
                  child: Text(AppTextStrings.snooze7Day,
                      style: AppFontStyles.bodyMedium16
                          .copyWith(color: AppColors.grey400)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppTextStrings.closeButton,
                    style: AppFontStyles.bodyMedium16
                        .copyWith(color: AppColors.grey900),
                  ),
                ),
              ],
            ),
            SizedBox(height: 26.h),
          ],
        ),
      ),
    );
  }
}
