import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SolutionBubble extends StatelessWidget {
  final String text;

  const SolutionBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BubblePainter(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        margin: EdgeInsets.only(left: 8.w),
        child: Text(text,
            textAlign: TextAlign.center,
            style: AppFontStyles.bodyBold16.copyWith(color: AppColors.grey900)),
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0);

    const r = 12.0; // 말풍선 모서리 라운드
    const tailWidth = 8.0;
    const tailHeight = 18.0;
    final tailOffsetY = size.height / 2; // 꼬리의 Y위치 (위쪽에서 얼마나 떨어질지)

    final path = Path()
      // 왼쪽 위 모서리부터 시작
      ..moveTo(r + tailWidth, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      // 오른쪽 위 → 오른쪽 아래
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      // 하단 → 왼쪽 아래
      ..lineTo(r + tailWidth, size.height)
      ..quadraticBezierTo(tailWidth, size.height, tailWidth, size.height - r)
      // 왼쪽 꼬리 부분 (뾰족 → 살짝 둥글게 변경)
      ..lineTo(tailWidth, tailOffsetY + tailHeight / 2)
      ..quadraticBezierTo(
        tailWidth * 0.3, tailOffsetY + tailHeight * 0.25, // 🎯 위쪽에서 안쪽으로
        0, tailOffsetY, // 🎯 꼬리 중앙 (끝점)
      )
      ..quadraticBezierTo(
        tailWidth * 0.3, tailOffsetY - tailHeight * 0.25, // 🎯 아래쪽으로 부드럽게 복귀
        tailWidth, tailOffsetY - tailHeight / 2, // 🎯 꼬리 아래쪽 끝과 연결
      )

      // 그냥 뾰족한 버전
      // ..lineTo(0, tailOffsetY)
      // ..lineTo(tailWidth,
      //     tailOffsetY - tailHeight / 2) // 위에 quadraticBezierTo이거 두개 없애고 넣기

      // 다시 위로 연결
      ..lineTo(tailWidth, r)
      ..quadraticBezierTo(tailWidth, 0, tailWidth + r, 0)
      ..close();

    // 부드러운 그림자 추가
    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
