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
  const FinishWidget({required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterIndex =
        ref.read(userViewModelProvider).step11;
    final characterList = [
      AppImages.cadoLove,
      AppImages.carrotLove
    ];
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
          Image.asset(
            characterList[characterIndex],
            width: 180.w,
            height: 180.h,
          )
        ],
      ),
    );
  }
}
