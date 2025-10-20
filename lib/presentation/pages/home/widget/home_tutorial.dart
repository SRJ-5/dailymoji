import 'package:flutter/material.dart';

class HomeTutorial extends StatefulWidget {
  final VoidCallback onClose;
  const HomeTutorial({required this.onClose, super.key});

  @override
  State<HomeTutorial> createState() => _HomeTutorialState();
}

class _HomeTutorialState extends State<HomeTutorial>
    with SingleTickerProviderStateMixin {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      child: Stack(
        children: [
          // 🔹 회색 반투명 배경
          Container(
            color: Colors.black.withOpacity(0.6),
          ),

          // 🔹 튜토리얼 내용
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "오늘의 감정을 선택하세요!",
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  "원하는 감정 이모지를 눌러보세요",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 80),
                // 손가락 커서나 이미지
                Image.asset(
                  'assets/images/hand_cursor.png',
                  width: 100,
                ),
              ],
            ),
          ),

          // 🔹 확인 버튼
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent),
                onPressed: () async {
                  setState(() => _opacity = 0.0);
                  await Future.delayed(const Duration(milliseconds: 500));
                  widget.onClose();
                },
                child: const Text("확인", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
