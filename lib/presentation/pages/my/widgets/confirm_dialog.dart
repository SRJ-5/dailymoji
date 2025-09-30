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
    // 배경 터치는 닫기, 다이얼로그 영역은 차단
    return GestureDetector(
      onTap: () => context.pop(), // 배경 터치시 다이얼로그 닫기
      child: Material(
        color: AppColors.black.withValues(alpha: 0.35), // 배경 오버레이
        child: Center(
          child: GestureDetector(
            // 다이얼로그 컨테이너 터치시 이벤트 차단 (배경 터치 이벤트가 전파되지 않음)
            onTap: () {},
            child: Container(
              width: 320.w, // 디자인 요구사항 그대로
              height: 186.h,
              padding: EdgeInsets.symmetric(horizontal: 34.w).copyWith(bottom: 24.h, top: 48.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "로그아웃 하시겠어요?",
                    style: AppFontStyles.heading3.copyWith(color: AppColors.grey900),
                  ),
                  SizedBox(height: 36.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          print("취소 버튼 클릭");
                          context.pop();
                        },
                        child: Container(
                          width: 120.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.green50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(width: 1, color: AppColors.grey200),
                          ),
                          child: Center(
                            child: Text(
                              '취소',
                              style: AppFontStyles.bodyMedium16.copyWith(color: AppColors.grey900),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      GestureDetector(
                        onTap: () {
                          print("확인");
                          // TODO: 로그아웃 로직 추가
                          context.pop();
                        },
                        child: Container(
                          width: 120.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.green400,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              '확인',
                              style: AppFontStyles.bodyMedium16.copyWith(color: AppColors.grey900),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
