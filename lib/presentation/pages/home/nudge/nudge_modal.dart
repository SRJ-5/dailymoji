// lib/presentation/nudge/nudge_modal.dart
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
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24.r),
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
            // Image.asset('assets/images/illustration_magnifier.png', width: 72.w, height: 72.w),
            SizedBox(height: 8.h),
            Text(
              '요즘 마음이 어떤지,\n내 감정 상태를 알아보세요!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton(
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                onPressed: () {
                  Navigator.of(context).pop();
                  onGo();
                },
                child: const Text('나의 감정 알아보러 가기'),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    onSnooze7d(); // 내부에서 스누즈 저장
                    Navigator.of(context).pop();
                  },
                  child: const Text('7일간 보지 않기'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
