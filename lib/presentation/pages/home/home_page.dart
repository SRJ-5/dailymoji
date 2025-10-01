// lib/presentation/pages/home/home_page.dart
// 0924 변경:
// 1. 선택된 이모지를 상태로 관리 (`selectedEmotion`)
// 2. 채팅 입력창 클릭 시, 선택된 이모지 정보를 `/chat` 라우트로 전달

import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/core/constants/emoji_assets.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

// 현재 선택된 이모지 상태를 관리하는 Provider
final selectedEmotionProvider = StateProvider<String?>((ref) => null);

// 백엔드에서 대사를 비동기적으로 가져오는 Provider
final homeDialogueProvider = FutureProvider<String>((ref) async {
  final selectedEmotion = ref.watch(selectedEmotionProvider);

// 🤩 RIN: userViewModelProvider를 통해 현재 사용자 프로필 정보를 가져옵니다.
  final userProfile = ref.watch(userViewModelProvider).userProfile;
  final personality = userProfile?.characterPersonality;
  // 🤩 RIN: Supabase DB에 저장된 dbValue('prob_solver' 등)를 사용해야 합니다.
  final personalityDbValue = CharacterPersonality.values
      .firstWhere(
        (e) => e.label == personality,
        orElse: () => CharacterPersonality.probSolver, // 기본값
      )
      .dbValue;
  final userNickNm = userProfile?.userNickNm;

  // 🤩 RIN: 기본 URL에 쿼리 파라미터 추가 로직 분기함
  final uri = Uri.parse('${ApiConfig.baseUrl}/dialogue/home');
  final queryParameters = {
    if (selectedEmotion != null) 'emotion': selectedEmotion,
    // 🤩 RIN: personality와 user_nick_nm을 쿼리 파라미터로 추가
    if (personalityDbValue != null) 'personality': personalityDbValue,
    if (userNickNm != null) 'user_nick_nm': userNickNm,
  };

  final finalUri = uri.replace(queryParameters: queryParameters);

  try {
    final response = await http.get(finalUri);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['dialogue'] as String;
    } else {
      // 에러 발생 시 기본 텍스트 반환
      return "안녕!\n오늘 기분은 어때?";
    }
  } catch (e) {
    print("Error fetching home dialogue: $e");
    return "안녕!\n오늘 기분은 어때?";
  }
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String displayText = "";
  // int _index = 0;
  // Timer? _timer;
  String? currentDialogue;

  void _startTyping(String newText) {
    // _timer?.cancel();
    setState(() {
      // displayText = "";
      displayText = newText;
      // _index = 0;
      // currentDialogue = newText;
    });

    // _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
    //   if (_index < (currentDialogue?.length ?? 0)) {
    //     setState(() {
    //       displayText += currentDialogue![_index];
    //       _index++;
    //     });
    //   } else {
    //     _timer?.cancel();
    //   }
    // });
  }

  void onEmojiTap(String emotionKey) {
    final selectedNotifier = ref.read(selectedEmotionProvider.notifier);

    if (selectedNotifier.state == emotionKey) {
      selectedNotifier.state = null;
    } else {
      selectedNotifier.state = emotionKey;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(homeDialogueProvider);
    });
  }

  @override
  void dispose() {
    // _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEmotion = ref.watch(selectedEmotionProvider);
    // final dialogueAsync = ref.watch(homeDialogueProvider);

    // dialogueAsync의 상태가 변경될 때마다 타이핑 효과를 다시 시작
    ref.listen(homeDialogueProvider, (_, next) {
      next.whenData((dialogue) {
        if (dialogue != currentDialogue) {
          _startTyping(dialogue);
        }
      });
    });

    return Scaffold(
      backgroundColor: Color(0xFFFEFBF4),
      // AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFFEFBF4),
        title: Image.asset(
          AppImages.dailymojiLogoBlack, // DailyMoji 로고 이미지 경로
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
                  AppImages.cadoProfile, // 중앙 캐릭터 이미지
                  height: 240.h,
                  width: 160.w,
                ),
                Positioned(
                  top: -6,
                  child: SvgPicture.asset(
                    AppIcons.bubbleUnder,
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
        onTap: () => context.push('/home/chat', extra: selectedEmotion),
        child: Container(
          color: Color(0xFFFEFBF4),
          child: Container(
            height: 40.h,
            margin: EdgeInsets.all(12.r),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "무엇이든 입력하세요",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SvgPicture.asset(AppIcons.send),
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

// 으아아아아아아아!!! 이게 문제였음 하.. 경로다른거!!
  // String get imoAssetPath => "assets/images/emoticon/emo_3d_${imoKey}_02.png";

  @override
  Widget build(BuildContext context) {
    // kEmojiAssetMap에서 이미지 경로를 가져옴. 만약 키가 없다면 기본 이미지(default)를 보여줌.
    final imagePath = kEmojiAssetMap[imoKey] ?? kEmojiAssetMap['default']!;
    final isSelected = selectedEmotion == imoKey;

    return GestureDetector(
      onTap: () => onEmojiTap(imoKey),
      child: isSelected
          ? Image.asset(imagePath, height: 80.h, width: 80.w, fit: BoxFit.cover)
          : ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, // R
                0.2126, 0.7152, 0.0722, 0, 0, // G
                0.2126, 0.7152, 0.0722, 0, 0, // B
                0, 0, 0, 1, 0, // A
              ]),
              child: Image.asset(imagePath,
                  height: 60.h, width: 60.w, fit: BoxFit.cover),
            ),
    );
  }
}
