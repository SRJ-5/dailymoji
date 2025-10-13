import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FinishWidget extends ConsumerWidget {
  final String text;
  final bool? srj5;
  const FinishWidget({required this.text, this.srj5});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterIndex =
        ref.read(userViewModelProvider).step11;

    return SizedBox(
      height: 566.h,
      child: Column(
        children: [
          SizedBox(height: 120.r),
          SizedBox(
            width: double.infinity,
            height: 72.h,
            child: Center(
                child: AppText(
              textAlign: TextAlign.center,
              text,
              style: AppFontStyles.heading2
                  .copyWith(color: AppColors.grey900),
            )),
          ),
          SizedBox(height: 40.r),
          srj5 == null
              ? Image.asset(
                  AppImages.characterListLove[characterIndex],
                  width: 180.w,
                  height: 180.h,
                )
              : Column(
                  children: [
                    SizedBox(height: 40),
                    Image.asset(
                      AppImages.srj5TestFinish,
                      width: 200.w,
                      height: 189.h,
                    ),
                  ],
                )
        ],
      ),
    );
  }
}
