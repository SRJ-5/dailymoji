import 'dart:async';
import 'package:dailymoji/presentation/pages/my/widgets/Ai_profile.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String defaultText = "안녕!\n지금 기분이 어때?";
  String displayText = "";
  int _index = 0;
  Timer? _timer;

  double angryScale = 1.0;
  double cryScale = 1.0;
  double shockedScale = 1.0;
  double sleepingScale = 1.0;
  double smileScale = 1.0;

  @override
  void initState() {
    super.initState();
    _startTyping("안녕!\n지금 기분이 어때?");
  }

  void _startTyping(String newText) {
    _timer?.cancel();
    setState(() {
      displayText = "";
      _index = 0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_index < newText.length) {
        setState(() {
          displayText += newText[_index];
          _index++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void onEmojiTap(String newText, String emotion) {
    // 텍스트 갱신
    _startTyping(newText);

    // 애니메이션 실행
    setState(() {
      if (emotion == "angry") {
        angryScale = 0.8;
      } else {
        angryScale = 1.0;
      }
      if (emotion == "cry") {
        cryScale = 0.8;
      } else {
        cryScale = 1.0;
      }
      if (emotion == "shocked") {
        shockedScale = 0.8;
      } else {
        shockedScale = 1.0;
      }
      if (emotion == "sleeping") {
        sleepingScale = 0.8;
      } else {
        sleepingScale = 1.0;
      }
      if (emotion == "smile") {
        smileScale = 0.8;
      } else {
        smileScale = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEFBF4),
      // AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFFEFBF4),
        title: Image.asset(
          "assets/images/logo.png", // DailyMoji 로고 이미지 경로
          height: 30,
        ),
      ),

      // Body
      body: Center(
        child: Align(
          alignment: const Alignment(0, -0.4),
          child: SizedBox(
            height: 400.h,
            width: 340.w,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  "assets/images/cado_00.png", // 중앙 캐릭터 이미지
                  height: 240.h,
                  width: 160.w,
                ),
                Positioned(
                  top: -110,
                  child: SizedBox(
                    height: 250.h,
                    width: 250.w,
                    child: Image.asset(
                      "assets/images/bubble_c 1.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  child: SizedBox(
                    width: 150.w,
                    child: Text(
                      displayText, // 타이핑 효과 적용된 텍스트
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ),
                // 감정 이모티콘들 (Stack + Positioned)
                Positioned(
                  bottom: 30.h,
                  child: GestureDetector(
                    onTap: () {
                      onEmojiTap("기분좋은 일이 \n있나보구나!\n무슨일일려나?ㅎㅎ", 'smile');
                    },
                    child: Image.asset(
                      "assets/images/emoticon/emo_3d_smile_02.png",
                      scale: smileScale,
                    ),
                  ),
                ),
                Positioned(
                  top: 94.h,
                  right: 38.w,
                  child: GestureDetector(
                    onTap: () {
                      onEmojiTap("왜..?\n무슨일이야!?\n나에게 얘기해볼래?", 'cry');
                    },
                    child: Image.asset(
                      "assets/images/emoticon/emo_3d_crying_02.png",
                      scale: cryScale,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 110.h,
                  left: 24.w,
                  child: GestureDetector(
                    onTap: () {
                      onEmojiTap("왜..?\n집중이 잘 안돼?\n나에게 얘기해볼래?", 'shocked');
                    },
                    child: Image.asset(
                      "assets/images/emoticon/emo_3d_shocked_02.png",
                      scale: shockedScale,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 110.h,
                  right: 24.w,
                  child: GestureDetector(
                    onTap: () {
                      onEmojiTap("왜..?\n요새 잠을 통모짜렐라\n나에게 얘기해볼래?", 'sleeping');
                    },
                    child: Image.asset(
                      "assets/images/emoticon/emo_3d_sleeping_02.png",
                      scale: sleepingScale,
                    ),
                  ),
                ),
                Positioned(
                  top: 94.h,
                  left: 38.w,
                  child: GestureDetector(
                    onTap: () {
                      onEmojiTap("왜..?\n기분이 안 좋아?\n나에게 얘기해줄래?", 'angry');
                    },
                    child: Image.asset(
                      "assets/images/emoticon/emo_3d_angry_02.png",
                      scale: angryScale,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomSheet: GestureDetector(
        onTap: () => context.go('/SolutionDescription'),
        child: Container(
          color: Color(0xFFFEFBF4),
          child: Container(
            height: 40.h,
            margin: EdgeInsets.all(12.r),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "무엇이든 입력하세요",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Image.asset("assets/icons/vector.png"),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}




// class EmojiButton extends StatelessWidget {
//   final String text;
//   final String emoji;
//   final String assetPath;
//   final double scale;
//   final double height;
//   final double width;
//   final VoidCallback onTap;

//   const EmojiButton({
//     super.key,
//     required this.text,
//     required this.emoji,
//     required this.assetPath,
//     required this.scale,
//     required this.height,
//     required this.width,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: height,
//       left: width,
//       child: GestureDetector(
//         onTap: onTap,
//         child: Image.asset(
//           assetPath,
//           scale: scale,
//         ),
//       ),
//     );
//   }
// }



// Stack(
//         children: [
//           BottomNavigationBar(
//             items: const [
//               BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
//               BottomNavigationBarItem(
//                   icon: Icon(Icons.bar_chart), label: "보고서"),
//               BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이"),
//             ],
//           ),

//           // ✅ 채팅 입력창 버튼 (네비게이터 위에 고정)
//           Positioned(
//             left: 16,
//             right: 16,
//             bottom: 60, // BottomNav 위에 띄우기
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(30),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Row(
//                 children: [
//                   const Expanded(
//                     child: Text(
//                       "무엇이든 입력하세요",
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   ),
//                   const Icon(Icons.send, color: Colors.grey),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),