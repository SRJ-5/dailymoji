import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class CustomToast extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback? onDismiss;

  const CustomToast({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 2),
    this.onDismiss,
  });

  @override
  State<CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<CustomToast> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // 토스트 표시
    _animationController.forward();

    // 자동 사라짐
    Future.delayed(widget.duration, () {
      _dismissToast();
    });
  }

  void _dismissToast() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              width: 320.w,
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.green500,
                  width: 1.sp,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF1D293D).withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(1.67.r),
                    width: 20.w,
                    height: 20.h,
                    child: SvgPicture.asset(
                      AppIcons.toastCheck,
                      colorFilter: ColorFilter.mode(
                        AppColors.grey900,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // 메시지 텍스트
                  AppText(
                    widget.message,
                    style: AppFontStyles.bodyRegular14.copyWith(
                      color: AppColors.grey900,
                    ),
                  ),
                  Spacer(),
                  // 닫기 버튼
                  GestureDetector(
                    onTap: _dismissToast,
                    child: Container(
                      padding: EdgeInsets.all(4.17.r),
                      width: 20.w,
                      height: 20.h,
                      child: SvgPicture.asset(
                        AppIcons.toastClose,
                        colorFilter: ColorFilter.mode(
                          AppColors.grey900,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 토스트 표시 헬퍼 함수
class ToastHelper {
  static OverlayEntry? _overlayEntry;

  static void showToast(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 기존 토스트가 있다면 제거
    hideToast();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 44.h,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: CustomToast(
              message: message,
              duration: duration,
              onDismiss: hideToast,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hideToast() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
