import 'dart:async';
import 'package:dailymoji/presentation/pages/my/widgets/Ai_profile.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DailyMojiHomePage extends StatefulWidget {
  const DailyMojiHomePage({super.key});

  @override
  State<DailyMojiHomePage> createState() => _DailyMojiHomePageState();
}

class _DailyMojiHomePageState extends State<DailyMojiHomePage> {
  final String fullText = "수니수니님, 오늘 왜 슬펐나요?";
  String displayText = "";
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_index < fullText.length) {
        setState(() {
          displayText += fullText[_index];
          _index++;
        });
      } else {
        _timer?.cancel();
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
      // ✅ AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Image.asset(
          "assets/images/logo.png", // DailyMoji 로고 이미지 경로
          height: 30,
        ),
      ),

      // ✅ Body
      body: Center(
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
              top: -146,
              child: Image.asset(
                "assets/images/bubble_c 1.png",
                height: 200.h,
                width: 200.w,
              ),
            ),
            Positioned(
              top: -77,
              child: Text(
                displayText, // ✅ 타이핑 효과 적용된 텍스트
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // ✅ 감정 이모티콘들 (Stack + Positioned)
            Positioned(
              bottom: -51.h,
              child: Image.asset(
                "assets/images/emoticon/emo_3d_smile_02.png",
                height: 60.h,
                width: 60.w,
              ),
            ),
            Positioned(
              top: 13.h,
              right: -53.w,
              child: Image.asset(
                "assets/images/emoticon/emo_3d_crying_02.png",
                height: 60.h,
                width: 60.w,
              ),
            ),
            Positioned(
              bottom: 29.h,
              left: -65.w,
              child: Image.asset(
                "assets/images/emoticon/emo_3d_shocked_02.png",
                height: 60.h,
                width: 60.w,
              ),
            ),
            Positioned(
              bottom: 29.h,
              right: -65.w,
              child: Image.asset(
                "assets/images/emoticon/emo_3d_sleeping_02.png",
                height: 60.h,
                width: 60.w,
              ),
            ),
            Positioned(
              top: 13.h,
              left: -53.w,
              child: Image.asset(
                "assets/images/emoticon/emo_3d_angry_02.png",
                height: 60.h,
                width: 60.w,
              ),
            ),
          ],
        ),
      ),

      bottomSheet: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AiProfil(),
              ));
        },
        child: Container(
          margin: EdgeInsets.all(12.r),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
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
      bottomNavigationBar: BottomBar(),
    );
  }
}





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