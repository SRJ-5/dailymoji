import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 4, 0); // 좌측 위
    path.lineTo(size.width / 2, size.height); // 가운데 아래
    path.lineTo(size.width * 3 / 4, 0); // 우측 위
    path.close();

    // ✅ 그림자 먼저 그림
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5), 4.0, false);

    // ✅ 삼각형 채우기
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) => false;
}
