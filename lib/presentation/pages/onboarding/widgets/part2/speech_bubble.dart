import 'package:dailymoji/core/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeechBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(206.17.w, 110.h),
      painter: SpeechBubblePainter(),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.grey100
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final triangleHeight = 16.0.w;
    final triangleWidth = 7.0.h;

    final rect =
        Rect.fromLTRB(triangleWidth, 0, size.width, size.height);
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(12));
    final path = Path()..addRRect(rrect);

    final trianglePath = Path();
    final centerY = size.height / 2;
    trianglePath.moveTo(
        triangleWidth, centerY - triangleHeight / 2); // 삼각형 왼쪽 위
    trianglePath.lineTo(0, centerY); // 뾰족 끝
    trianglePath.lineTo(triangleWidth,
        centerY + triangleHeight / 2); // 삼각형 왼쪽 아래
    trianglePath.close();
    path.addPath(trianglePath, Offset.zero);

    canvas.drawShadow(
        path,
        Color(0xff1D293D).withAlpha((0.3 * 255).toInt()),
        2,
        false);

    canvas.drawPath(path, fillPaint);

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
