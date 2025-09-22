import 'dart:async';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

const String angry = "angry";
const String crying = "crying";
const String shocked = "shocked";
const String sleeping = "sleeping";
const String smile = "smile";

const String defaultText1 = "안녕!\n지금 기분이 어때?";
const String angryText = "왜..?\n기분이 안 좋아?\n나에게 얘기해줄래?";
const String cryingText = "왜..?\n무슨일이야!?\n나에게 얘기해볼래?";
const String shockedText = "왜..?\n집중이 잘 안돼?\n나에게 얘기해볼래?";
const String sleepingText = "왜..?\n요새 잠을 통모짜렐라\n나에게 얘기해볼래?";
const String smileText = "기분좋은 일이 \n있나보구나!\n무슨일일려나?ㅎㅎ";

const String angryImage = "assets/images/emoticon/emo_3d_angry_02.png";
const String cryingImage = "assets/images/emoticon/emo_3d_crying_02.png";
const String shockedImage = "assets/images/emoticon/emo_3d_shocked_02.png";
const String sleepingImage = "assets/images/emoticon/emo_3d_sleeping_02.png";
const String smileImage = "assets/images/emoticon/emo_3d_smile_02.png";

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

  String? selectedEmotion;
  bool angrySelected = false;
  bool cryingSelected = false;
  bool shockedSelected = false;
  bool sleepingSelected = false;
  bool smileSelected = false;

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
      if (selectedEmotion == emotion) {
        selectedEmotion = null; // 다시 누르면 해제
      } else {
        selectedEmotion = emotion;
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
                  child: SizedBox(
                    height: 95.h,
                    width: 180.w,
                    child: Image.asset(
                      "assets/images/Bubble.png",
                      fit: BoxFit.fitWidth,
                    ),
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
                    child: Imoge(
                        imo: smile,
                        imoText: smileText,
                        imoImage: smileImage,
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
                Positioned(
                    top: 94.h,
                    right: 25.w,
                    child: Imoge(
                        imo: crying,
                        imoText: cryingText,
                        imoImage: cryingImage,
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
                Positioned(
                    bottom: 110.h,
                    left: 15.w,
                    child: Imoge(
                        imo: shocked,
                        imoText: shockedText,
                        imoImage: shockedImage,
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
                Positioned(
                    bottom: 110.h,
                    right: 15.w,
                    child: Imoge(
                        imo: sleeping,
                        imoText: sleepingText,
                        imoImage: sleepingImage,
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
                Positioned(
                    top: 94.h,
                    left: 25.w,
                    child: Imoge(
                        imo: angry,
                        imoText: angryText,
                        imoImage: angryImage,
                        selectedEmotion: selectedEmotion,
                        onEmojiTap: onEmojiTap)),
              ],
            ),
          ),
        ),
      ),

      bottomSheet: GestureDetector(
        onTap: () => context.go('/home/ChatPage'),
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

class Imoge extends StatelessWidget {
  final String imo;
  final String imoText;
  final String imoImage;
  final String? selectedEmotion;
  final void Function(String, String) onEmojiTap;

  const Imoge({
    required this.imo,
    required this.imoText,
    required this.imoImage,
    required this.selectedEmotion,
    required this.onEmojiTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        selectedEmotion == imo
            ? onEmojiTap(defaultText1, imo)
            : onEmojiTap(imoText, imo);
      },
      child: selectedEmotion == imo
          ? SizedBox(
              height: 80.h,
              width: 80.w,
              child: Image.asset(
                imoImage,
                fit: BoxFit.cover,
              ),
            )
          : ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, // R
                0.2126, 0.7152, 0.0722, 0, 0, // G
                0.2126, 0.7152, 0.0722, 0, 0, // B
                0, 0, 0, 1, 0, // A
              ]),
              child: SizedBox(
                height: 60.h,
                width: 60.w,
                child: Image.asset(
                  imoImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
    );
  }
}
