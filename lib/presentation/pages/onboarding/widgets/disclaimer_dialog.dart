import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class DisclaimerDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 배경 터치는 닫기 방지 (면책 동의는 중요하므로)
    return PopScope(
      canPop: false, // 뒤로가기 버튼 비활성화
      child: Material(
        color: AppColors.black.withValues(alpha: 0.35), // 배경 오버레이
        child: Center(
          child: GestureDetector(
            // 다이얼로그 컨테이너 터치시 이벤트 차단
            onTap: () {},
            child: Container(
              width: 320.w,
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  AppText(
                    "건강 면책 및 주의 안내",
                    style: AppFontStyles.heading3.copyWith(color: AppColors.grey900),
                  ),
                  SizedBox(height: 8.h),

                  // 본문 내용 (스크롤 가능)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 300.h, // 최대 높이 제한
                    ),
                    child: SingleChildScrollView(
                      child: AppText(
                        "저희 앱은 마음의 안정과 휴식을 돕기 위한 일반적인 정보를 제공합니다."
                        "의학적 진단이나 치료를 대신하지 않으며, 사용자의 건강 상태에 따라 무리가 될 수 있는 활동은 피해야 합니다.\n\n"
                        "앱의 콘텐츠는 단순한 가이드로 제공되며, 그 정확성·완전성·유용성에 대해 어떠한 보증도 하지 않습니다."
                        "앱 사용 중 어지럼증, 통증, 호흡 곤란 등 불편감이 느껴질 경우 즉시 중단하고 전문가(의사 또는 심리 상담사)와 상의하세요.\n\n"
                        "저희 앱을 사용함으로써 발생할 수 있는 모든 신체적 정신적 부작용에 대해 책임은 사용자 본인에게 있으며, 도으이 버튼을 누르시면 이에 도의한 것으로 간주됩니다.",
                        style: AppFontStyles.bodyRegular14.copyWith(color: AppColors.grey900),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 하단 버튼들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 취소 버튼
                      GestureDetector(
                        onTap: () {
                          // 취소 시 로그인 화면으로 돌아가기
                          context.go('/login');
                        },
                        child: Container(
                          width: 120.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.green50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              width: 1,
                              color: AppColors.grey200,
                            ),
                          ),
                          child: Center(
                            child: AppText(
                              '취소',
                              style: AppFontStyles.bodyMedium16.copyWith(color: AppColors.grey900),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // 동의합니다 버튼
                      GestureDetector(
                        onTap: () {
                          // 동의 시 다이얼로그 닫기
                          context.pop();
                        },
                        child: Container(
                          width: 120.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.green500,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: AppText(
                              '동의합니다',
                              style: AppFontStyles.bodyMedium16.copyWith(color: AppColors.grey50),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
