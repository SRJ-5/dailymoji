import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/domain/enums/character_personality.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class character_box extends StatelessWidget {
  final double viewportFraction;
  final String personality;
  final String characterImage;
  final int index;
  final Function(
      {required int selectNum,
      required String aiPersonality}) onSelect;
  character_box(
      {super.key,
      required this.viewportFraction,
      required this.personality,
      required this.characterImage,
      required this.onSelect,
      required this.index});

  @override
  Widget build(BuildContext context) {
    final _personalitiesMy = CharacterPersonality.values
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
            height: 260.h,
            child: Image.asset(
              characterImage,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 12.r),
          AppText(
            personality,
            textAlign: TextAlign.center,
            style: AppFontStyles.bodySemiBold16
                .copyWith(color: AppColors.grey900),
          ),
          SizedBox(height: 20.r),
          GestureDetector(
            onTap: () {
              onSelect(
                  selectNum: index,
                  aiPersonality: _personalitiesMy[index]);
            },
            child: Center(
              child: Container(
                width: 105.w,
                height: 40.h,
                padding: EdgeInsets.symmetric(vertical: 8.h)
                    .copyWith(left: 16.w, right: 10.w),
                decoration: BoxDecoration(
                  color: AppColors.green500,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Row(
                    children: [
                      AppText(
                        '선택하기',
                        style: AppFontStyles.bodyMedium14
                            .copyWith(color: AppColors.grey50),
                      ),
                      SizedBox(width: 10.8.r),
                      SvgPicture.asset(AppIcons.arrowForward,
                          width: 14.4.w,
                          height: 11.98.h,
                          colorFilter: ColorFilter.mode(
                              AppColors.grey50, BlendMode.srcIn))
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
