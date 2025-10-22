import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/domain/enums/character_personality.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class CharacterBox extends StatelessWidget {
  final double viewportFraction;
  final String personality;
  final String characterImage;
  final int index;
  final bool isOnboarding;
  final Function(
      {required int selectNum,
      required String aiPersonality}) onSelect;
  CharacterBox(
      {super.key,
      required this.viewportFraction,
      required this.personality,
      required this.characterImage,
      required this.onSelect,
      required this.isOnboarding,
      required this.index});

  @override
  Widget build(BuildContext context) {
    final personalitiesMy = CharacterPersonality.values
        .map((e) => e.myLabel)
        .toList();
    return Container(
      width: 288.w,
      height: 440.h,
      padding: EdgeInsets.symmetric(horizontal: 16.h)
          .copyWith(top: 36.h, bottom: 24.h),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 4),
              color: Color.fromRGBO(29, 41, 61, 0.1),
              blurRadius: 8,
              spreadRadius: -2,
            )
          ],
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(24.r),
          border:
              Border.all(width: 1, color: AppColors.grey200)),
      child: Column(
        children: [
          SizedBox(
            width: 198.w,
            height: 250.h,
            child: Image.asset(
              characterImage,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 12.r),
          AppText(
            personality,
            textAlign: TextAlign.center,
            style: AppFontStyles.bodySemiBold16
                .copyWith(color: AppColors.grey900),
          ),
          SizedBox(height: 18.r),
          GestureDetector(
            onTap: () {
              onSelect(
                  selectNum: index,
                  aiPersonality: personalitiesMy[index]);
            },
            child: Consumer(
              builder: (context, ref, child) {
                final userState =
                    ref.watch(userViewModelProvider);
                return Center(
                  child: Container(
                    width: 105.w,
                    height: 40.h,
                    // padding: EdgeInsets.symmetric(vertical: 8.h).copyWith(left: 16.w, right: 10.w),
                    decoration: BoxDecoration(
                      color: isOnboarding
                          ? AppColors.green500
                          : userState.userProfile!
                                      .characterNum ==
                                  index
                              ? AppColors.green700
                              : AppColors.green500,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            isOnboarding
                                ? "선택하기"
                                : userState.userProfile!
                                            .characterNum ==
                                        index
                                    ? "선택됨"
                                    : '선택하기',
                            style: AppFontStyles.bodyMedium14
                                .copyWith(
                                    color: AppColors.grey50),
                          ),
                          if (isOnboarding)
                            SizedBox(width: 10.8.r),
                          if (isOnboarding)
                            SvgPicture.asset(
                                AppIcons.arrowForward,
                                width: 14.4.w,
                                height: 11.98.h,
                                colorFilter: ColorFilter.mode(
                                    AppColors.grey50,
                                    BlendMode.srcIn))
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
