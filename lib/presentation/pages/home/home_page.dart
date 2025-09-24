// lib/presentation/pages/home/home_page.dart
// 0924 변경:
// 1. 선택된 이모지를 상태로 관리 (`selectedEmotion`)
// 2. 채팅 입력창 클릭 시, 선택된 이모지 정보를 `/chat` 라우트로 전달

import 'dart:async';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String displayText = "";
  int _index = 0;
  Timer? _timer;

  String? selectedEmotion; // 선택된 이모지 이름 (예: "smile")

  static const String defaultText = "안녕!\n지금 기분이 어때?";
  final Map<String, String> emotionTexts = {
    "angry": "왜..?\n기분이 안 좋아?\n나에게 얘기해줄래?",
    "crying": "왜..?\n무슨일이야!?\n나에게 얘기해볼래?",
    "shocked": "왜..?\n집중이 잘 안돼?\n나에게 얘기해볼래?",
    "sleeping": "왜..?\n요새 잠을 잘 못자?\n나에게 얘기해볼래?",
    "smile": "기분좋은 일이 \n있나보구나!\n무슨일일려나?ㅎㅎ"
  };

  @override
  void initState() {
    super.initState();
    _startTyping(defaultText);
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

  void onEmojiTap(String emotionKey) {
    setState(() {
      if (selectedEmotion == emotionKey) {
        selectedEmotion = null; // 다시 누르면 해제
        _startTyping(defaultText);
      } else {
        selectedEmotion = emotionKey;
        _startTyping(emotionTexts[emotionKey] ?? defaultText);
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
                  top: -6,
                  child: SvgPicture.asset(
                    "assets/images/Bubble.svg",
                    height: 95.h,
                    width: 180.w,
                  ),
                ),
                Positioned(
                  top: 3,
                  child: SizedBox(
                    width: 150.w,
                    child: Text(
                      displayText, // 타이핑 효과 적용된 텍스트
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF333333),
                        fontFamily: 'Pretendard',
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
                    bottom: 15.h,
                    child: _Imoge(
                        imoKey: "smile",
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
                Positioned(
                    top: 94.h,
                    right: 25.w,
                    child: _Imoge(
                        imoKey: "crying",
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
                Positioned(
                    bottom: 110.h,
                    left: 15.w,
                    child: _Imoge(
                        imoKey: "shocked",
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
                Positioned(
                    bottom: 110.h,
                    right: 15.w,
                    child: _Imoge(
                        imoKey: "sleeping",
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
                Positioned(
                    top: 94.h,
                    left: 25.w,
                    child: _Imoge(
                        imoKey: "angry",
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
              ],
            ),
          ),
        ),
      ),

      bottomSheet: GestureDetector(
        onTap: () => context.push('/chat', extra: selectedEmotion),
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

class _Imoge extends StatelessWidget {
  final String imoKey;
  final String? selectedEmotion;
  final void Function(String) onEmojiTap;

  const _Imoge(
      {required this.imoKey,
      required this.selectedEmotion,
      required this.onEmojiTap});

  String get imoAssetPath => "assets/images/emoticon/emo_3d_${imoKey}_02.png";

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedEmotion == imoKey;
    return GestureDetector(
      onTap: () => onEmojiTap(imoKey),
      child: isSelected
          ? Image.asset(imoAssetPath,
              height: 80.h, width: 80.w, fit: BoxFit.cover)
          : ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, // R
                0.2126, 0.7152, 0.0722, 0, 0, // G
                0.2126, 0.7152, 0.0722, 0, 0, // B
                0, 0, 0, 1, 0, // A
              ]),
              child: Image.asset(imoAssetPath,
                  height: 60.h, width: 60.w, fit: BoxFit.cover),
            ),
    );
  }
}
