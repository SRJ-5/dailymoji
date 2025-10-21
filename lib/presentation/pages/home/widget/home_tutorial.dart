import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 홈 튜토리얼: 전체 이미지를 뒤덮고, 중앙(또는 하단)의 확인 버튼만 직접 구현
class HomeTutorial extends StatelessWidget {
  final VoidCallback onClose;
  const HomeTutorial({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 튜토리얼 이미지 한 장으로 오버레이
        Image.asset(
          AppImages.homeTutorial, // ⬅️ e.g. 'assets/images/tutorial_home.png'
          fit: BoxFit.fill, // 보고 주신 레이아웃과 동일하게 꽉 채움
        ),

        // 중앙(또는 하단) 확인 버튼 — 위치는 이미지에 맞춰 조정
        Positioned(
          // 스크린샷 기준: 하단 중앙 버튼 느낌 → 값은 적당히 조정하세요
          bottom: 60.h,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green500,
                padding: EdgeInsets.symmetric(horizontal: 46.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: AppText(
                '확인',
                style: AppFontStyles.bodyMedium16.copyWith(
                  color: AppColors.grey50,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
