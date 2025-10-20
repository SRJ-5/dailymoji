import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/presentation/pages/home/widget/emoji_video.dart';
import 'package:dailymoji/presentation/pages/home/widget/home_tutorial.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/domain/enums/emoji_asset.dart';
import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dailymoji/presentation/providers/background_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHomeTutorialSeenKey = 'home_tutorial_seen_v1';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String displayText = "";
  String? currentDialogue;

  void _startTyping(String newText) {
    setState(() {
      displayText = newText.replaceAll(r'\n', '\n');
    });
  }

  void onEmojiTap(String emotionKey) {
    final selectedNotifier = ref.read(selectedEmotionProvider.notifier);
    // ✅ 변경: 단순 토글만 유지(확대/축소/색상 변경 로직 제거)
    selectedNotifier.state =
        (selectedNotifier.state == emotionKey) ? null : emotionKey;
  }

  bool _showTutorial = false;
  bool _homeSeen = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(homeDialogueProvider);
      ref.invalidate(selectedEmotionProvider);
    });
    _initHomeTutorialPrefs();
  }

  Future<void> _initHomeTutorialPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _homeSeen = prefs.getBool(_kHomeTutorialSeenKey) ?? false;

    if (!mounted) return;
    setState(() {
      _loaded = true;
      // 첫 진입 시: 아직 안 봤다면 보여주기
      if (!_homeSeen) _showTutorial = true;
    });
  }

  Future<void> _handleHomeTutorialClose() async {
    if (!mounted) return;
    setState(() => _showTutorial = false);
    // 누른 순간에만 '봤다' 저장
    final prefs = await SharedPreferences.getInstance();
    if (!_homeSeen) {
      _homeSeen = true;
      await prefs.setBool(_kHomeTutorialSeenKey, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCharacterNum =
        ref.read(userViewModelProvider).userProfile!.characterNum;
    final selectedEmotion = ref.watch(selectedEmotionProvider);

    // Provider에서 현재 배경 경로 가져오기
    final backgroundPath = ref.watch(backgroundImageProvider);

    // 말풍선 텍스트 변경 리스너
    ref.listen(homeDialogueProvider, (_, next) {
      next.whenData((dialogue) {
        if (dialogue != currentDialogue) {
          _startTyping(dialogue);
        }
      });
    });

    if (!_loaded) {
      return Scaffold(
        body: Center(
          child: Container(
            height: double.infinity,
            width: double.infinity,
            color: AppColors.yellow50,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.green400),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          // 변경: 바디를 AppBar 뒤로 연장 → 배경이 StatusBar까지 꽉 차게
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          // 변경: 투명 AppBar + 좌측 로고(디자인 1번처럼)
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 16.w,
            title: Image.asset(AppImages.dailymojiLogoBlack, height: 30),
            actions: [
              IconButton(
                onPressed: () {
                  context.go("/home/background_setting");
                },
                icon: SvgPicture.asset(AppIcons.setting,
                    width: 19.w, height: 19.h),
              ),
              SizedBox(width: 12.w),
            ],
          ),

          // ✅ 변경: 배경 이미지를 화면 가득(상단 SafeArea 없이)
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  backgroundPath,
                  fit: BoxFit.cover,
                ),
              ),

              // 중앙 캐릭터 + 말풍선
              Positioned(
                top: 144.h,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        SvgPicture.asset(
                          AppIcons.bubbleUnder,
                          height: 110.h,
                          width: 200.w,
                        ),
                        Transform.translate(
                          offset: Offset(0, -7.h),
                          child: SizedBox(
                            width: 160.w,
                            height: 110.h,
                            child: Center(
                              child: AppText(
                                displayText.isNotEmpty
                                    ? displayText
                                    : AppTextStrings.defaultGreeting,
                                style: AppFontStyles.bodyBold16
                                    .copyWith(color: AppColors.grey900),
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    Image.asset(
                      AppImages.characterListProfile[selectedCharacterNum!],
                      height: 168.h,
                      width: 168.w,
                    ),
                  ],
                ),
              ),

              // ✅ 변경: 가로 스크롤 이모지 리스트(확대/컬러 필터 제거)
              Positioned(
                bottom: 98.h,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 122.h,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, idx) {
                      // 원하는 노출 순서 정의
                      const keys = [
                        "angry",
                        "crying",
                        "shocked",
                        "sleeping",
                        "smile",
                      ];
                      final key = keys[idx % keys.length];
                      return _EmojiItem(
                        emoKey: key,
                        isSelected: selectedEmotion == key,
                        onTap: () => onEmojiTap(key),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemCount: 5,
                  ),
                ),
              ),

              // SizedBox(height: 84.h),
              // 하단 입력 바(기존 유지)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12.h,
                child: GestureDetector(
                  onTap: () {
                    final emotion = selectedEmotion; // 백업
                    context.go('/home/chat', extra: emotion);
                    ref.invalidate(selectedEmotionProvider);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Container(
                      height: 40.h,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              "무엇이든 입력하세요",
                              style: AppFontStyles.bodyRegular14
                                  .copyWith(color: AppColors.grey600),
                            ),
                          ),
                          selectedEmotion == null
                              ? SvgPicture.asset(AppIcons.send)
                              : SvgPicture.asset(AppIcons.sendOrange),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomBar(),
        ),
        // ⬇️ Report와 동일한 “오버레이 위젯” 방식
        if (_showTutorial)
          HomeTutorial(
            onClose: _handleHomeTutorialClose,
          ),
      ],
    );
  }
}

//이모지 요소
class _EmojiItem extends StatelessWidget {
  final String emoKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmojiItem({
    required this.emoKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 하... 드디어 문제 해결..
    // 백엔드와 프론트까지에서 클러스터에 대한 전반적인 용어정리가 안됨
    // 백엔드에선  "angry", "crying", "sleeping", "shocked", "smile"데이터를 원하고
    // 프론트랑 프로바이더, 에셋경로, 기타 전반적인 곳은 'neg_high', 'neg_low', 'sleep', 'adhd', 'positive'를 원함
    const emotionClusterMap = {
      "angry": AppTextStrings.negHigh,
      "crying": AppTextStrings.negLow,
      "sleeping": AppTextStrings.sleep,
      "shocked": AppTextStrings.adhd,
      "smile": AppTextStrings.positive,
    };

    final videoPath = EmojiAsset.fromString(emotionClusterMap[emoKey]!).video;

    const emotionTextMap = {
      "angry": AppTextStrings.clusterNegHigh,
      "crying": AppTextStrings.clusterNegLow,
      "sleeping": AppTextStrings.clusterSleep,
      "shocked": AppTextStrings.clusterAdhd,
      "smile": AppTextStrings.clusterPositive,
    };
    final label = emotionTextMap[emoKey] ?? "";

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // 아이콘 타일
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            width: 100.w,
            height: 122.h,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected ? AppColors.orange300 : AppColors.grey200,
                width: isSelected ? 2.r : 1.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6.r,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                LoopVideo(assetPath: videoPath, width: 60.w, height: 60.h),
                SizedBox(height: 8.h),
                // 라벨
                SizedBox(
                  width: 72.w,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFontStyles.bodyRegular12.copyWith(
                      color: AppColors.grey900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// // lib/presentation/pages/home/home_page.dart
// // 0924 변경:
// // 1. 선택된 이모지를 상태로 관리 (`selectedEmotion`)
// // 2. 채팅 입력창 클릭 시, 선택된 이모지 정보를 `/chat` 라우트로 전달

// import 'package:dailymoji/core/constants/app_text_strings.dart';
// // import 'package:dailymoji/presentation/pages/home/widget/home_tutorial.dart';
// import 'package:dailymoji/presentation/widgets/app_text.dart';
// import 'package:dailymoji/domain/enums/emoji_asset.dart';
// import 'package:dailymoji/core/providers.dart';
// import 'package:dailymoji/core/styles/colors.dart';
// import 'package:dailymoji/core/styles/fonts.dart';
// import 'package:dailymoji/core/styles/icons.dart';
// import 'package:dailymoji/core/styles/images.dart';
// import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
// import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// // // 현재 선택된 이모지 상태를 관리하는 Provider
// // final selectedEmotionProvider = StateProvider<String?>((ref) => null);

// // // 백엔드에서 대사를 비동기적으로 가져오는 Provider
// // final homeDialogueProvider = FutureProvider<String>((ref) async {
// //   final selectedEmotion = ref.watch(selectedEmotionProvider);

// // // 🤩 RIN: userViewModelProvider를 통해 현재 사용자 프로필 정보를 가져옵니다.
// //   final userProfile = ref.watch(userViewModelProvider).userProfile;
// //   final personality = userProfile?.characterPersonality;
// //   // 🤩 RIN: Supabase DB에 저장된 dbValue('prob_solver' 등)를 사용해야 합니다.
// //   final personalityDbValue = CharacterPersonality.values
// //       .firstWhere(
// //         (e) => e.label == personality,
// //         orElse: () => CharacterPersonality.probSolver, // 기본값
// //       )
// //       .dbValue;
// //   final userNickNm = userProfile?.userNickNm;

// //   // 🤩 RIN: 기본 URL에 쿼리 파라미터 추가 로직 분기함
// //   final uri = Uri.parse('${ApiConfig.baseUrl}/dialogue/home');
// //   final queryParameters = {
// //     if (selectedEmotion != null) 'emotion': selectedEmotion,
// //     // 🤩 RIN: personality와 user_nick_nm을 쿼리 파라미터로 추가
// //     if (personalityDbValue != null) 'personality': personalityDbValue,
// //     if (userNickNm != null) 'user_nick_nm': userNickNm,
// //   };

// //   final finalUri = uri.replace(queryParameters: queryParameters);

// //   try {
// //     final response = await http.get(finalUri);

// //     if (response.statusCode == 200) {
// //       final data = jsonDecode(utf8.decode(response.bodyBytes));
// //       return data['dialogue'] as String;
// //     } else {
// //       // 에러 발생 시 기본 텍스트 반환
// //       return "안녕!\n오늘 기분은 어때?";
// //     }
// //   } catch (e) {
// //     print("Error fetching home dialogue: $e");
// //     return "안녕!\n오늘 기분은 어때?";
// //   }
// // });

// class HomePage extends ConsumerStatefulWidget {
//   const HomePage({super.key});

//   @override
//   ConsumerState<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends ConsumerState<HomePage> {
//   String displayText = "";
//   // int _index = 0;
//   // Timer? _timer;
//   String? currentDialogue;
//   // bool _showTutorial = true;

//   void _startTyping(String newText) {
//     // _timer?.cancel();
//     setState(() {
//       // displayText = "";
//       displayText = newText.replaceAll(r'\n', '\n');
//       // _index = 0;
//       // currentDialogue = newText;
//     });

//     // _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
//     //   if (_index < (currentDialogue?.length ?? 0)) {
//     //     setState(() {
//     //       displayText += currentDialogue![_index];
//     //       _index++;
//     //     });
//     //   } else {
//     //     _timer?.cancel();
//     //   }
//     // });
//   }

//   void onEmojiTap(String emotionKey) {
//     final selectedNotifier = ref.read(selectedEmotionProvider.notifier);
//     print(selectedNotifier.state);
//     if (selectedNotifier.state == emotionKey) {
//       selectedNotifier.state = null;
//     } else {
//       selectedNotifier.state = emotionKey;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       ref.invalidate(homeDialogueProvider);
//       ref.invalidate(
//           selectedEmotionProvider); // 고라우터라 디스포즈가 안먹히는거같아서 그냥 이동할때 초기화
//     });
//   }

//   @override
//   void dispose() {
//     // _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedCharacterNum =
//         ref.read(userViewModelProvider).userProfile!.characterNum;
//     final selectedEmotion = ref.watch(selectedEmotionProvider);
//     // final dialogueAsync = ref.watch(homeDialogueProvider);

//     // dialogueAsync의 상태가 변경될 때마다 타이핑 효과를 다시 시작
//     ref.listen(homeDialogueProvider, (_, next) {
//       next.whenData((dialogue) {
//         if (dialogue != currentDialogue) {
//           _startTyping(dialogue);
//         }
//       });
//     });

//     return Stack(
//       children: [
//         Scaffold(
//           backgroundColor: AppColors.yellow50,
//           // AppBar
//           appBar: AppBar(
//             elevation: 0,
//             backgroundColor: AppColors.yellow50,
//             centerTitle: false,
//             title: Image.asset(
//               AppImages.dailymojiLogoBlack, // DailyMoji 로고 이미지 경로
//               height: 30,
//             ),
//           ),

//           // Body
//           body: Center(
//             child: Align(
//               alignment: const Alignment(0, -0.1),
//               child: SizedBox(
//                 height: 340.h,
//                 width: 340.w,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   clipBehavior: Clip.none,
//                   children: [
//                     Image.asset(
//                       // 없애기
//                       AppImages.characterListProfile[
//                           selectedCharacterNum!], // 중앙 캐릭터 이미지
//                       height: 240.h,
//                       width: 160.w,
//                     ),
//                     Positioned(
//                       top: -50.h,
//                       child: SvgPicture.asset(
//                         AppIcons.bubbleUnder,
//                         height: 110.h,
//                         width: 200.w,
//                       ),
//                     ),
//                     Positioned(
//                       top: -57.h,
//                       child: SizedBox(
//                         width: 150.w,
//                         height: 110.h,
//                         child: Center(
//                           child: AppText(
//                             displayText, // 타이핑 효과 적용된 텍스트
//                             style: AppFontStyles.bodyBold16
//                                 .copyWith(color: AppColors.grey900),
//                             textAlign: TextAlign.center,
//                             maxLines: 4,
//                             overflow: TextOverflow.ellipsis,
//                             softWrap: true,
//                           ),
//                         ),
//                       ),
//                     ),

//                     // 감정 이모티콘들 (Stack + Positioned)
//                     Positioned(
//                         top: 69.h,
//                         left: 55.w,
//                         child: Container(
//                           alignment: Alignment.center,
//                           height: 54.h,
//                           width: 54.w,
//                           child: _Imoge(
//                               imoKey: "angry",
//                               selectedEmotion: selectedEmotion,
//                               onEmojiTap: onEmojiTap),
//                         )),
//                     Positioned(
//                         bottom: 103.h,
//                         left: 22.w,
//                         child: Container(
//                           alignment: Alignment.center,
//                           height: 54.h,
//                           width: 54.w,
//                           child: _Imoge(
//                               imoKey: "crying",
//                               selectedEmotion: selectedEmotion,
//                               onEmojiTap: onEmojiTap),
//                         )),
//                     Positioned(
//                         bottom: 8.h,
//                         left: 118.w,
//                         child: Container(
//                           alignment: Alignment.center,
//                           height: 54.h,
//                           width: 54.w,
//                           child: _Imoge(
//                               imoKey: "shocked",
//                               selectedEmotion: selectedEmotion,
//                               onEmojiTap: onEmojiTap),
//                         )),
//                     Positioned(
//                         bottom: 67.h,
//                         right: 40.w,
//                         child: Container(
//                           alignment: Alignment.center,
//                           height: 54.h,
//                           width: 54.w,
//                           child: _Imoge(
//                               imoKey: "sleeping",
//                               selectedEmotion: selectedEmotion,
//                               onEmojiTap: onEmojiTap),
//                         )),
//                     Positioned(
//                         top: 87.h,
//                         right: 48.w,
//                         child: Container(
//                           alignment: Alignment.center,
//                           height: 54.h,
//                           width: 54.w,
//                           child: _Imoge(
//                               imoKey: "smile",
//                               selectedEmotion: selectedEmotion,
//                               onEmojiTap: onEmojiTap),
//                         )),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           bottomSheet: GestureDetector(
//             onTap: () {
//               ref.invalidate(
//                   selectedEmotionProvider); // 고라우터라 디스포즈가 안먹히는거같아서 그냥 이동할때 초기화
//               context.go('/home/chat', extra: selectedEmotion);
//             },
//             child: Container(
//               color: AppColors.yellow50,
//               child: Container(
//                 height: 40.h,
//                 margin: EdgeInsets.all(12.r),
//                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
//                 decoration: BoxDecoration(
//                   color: AppColors.white,
//                   borderRadius: BorderRadius.circular(12.r),
//                   border: Border.all(color: AppColors.grey200),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: AppText(
//                         "무엇이든 입력하세요",
//                         style: AppFontStyles.bodyRegular14
//                             .copyWith(color: AppColors.grey600),
//                       ),
//                     ),
//                     selectedEmotion == null
//                         ? SvgPicture.asset(AppIcons.send)
//                         : SvgPicture.asset(AppIcons.sendOrange),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           bottomNavigationBar: BottomBar(),
//         ),
//         // 튜토리얼
//         // if (_showTutorial)
//         //   HomeTutorial(onClose: () {
//         //     setState(() => _showTutorial = false);
//         //   }),
//       ],
//     );
//   }
// }

// class _Imoge extends StatelessWidget {
//   final String imoKey;
//   final String? selectedEmotion;
//   final void Function(String) onEmojiTap;

//   const _Imoge(
//       {required this.imoKey,
//       required this.selectedEmotion,
//       required this.onEmojiTap});

// // 으아아아아아아아!!! 이게 문제였음 하.. 경로다른거!!
//   // String get imoAssetPath => "assets/images/emoticon/emo_3d_${imoKey}_02.png";

//   @override
//   Widget build(BuildContext context) {
//     // EmojiAsset enum에서 이미지 경로를 가져옴
//     final imagePath = EmojiAsset.fromString(imoKey).asset;
//     final isSelected = selectedEmotion == imoKey;

//     // ✅ 각 이모지 키별로 표시할 텍스트를 매핑
//     final emotionTextMap = {
//       "angry": "불안/분노",
//       "crying": "우울/무기력",
//       "sleeping": "불규칙 수면",
//       "shocked": "집중력 저하",
//       "smile": "평온/회복",
//     };

//     // ✅ 현재 이모지의 텍스트 (없을 경우 빈 문자열)
//     final emotionLabel = emotionTextMap[imoKey] ?? "";

//     return GestureDetector(
//       onTap: () => onEmojiTap(imoKey),
//       child: Stack(
//           alignment: Alignment.center,
//           clipBehavior: Clip.none,
//           children: [
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 500),
//               curve: Curves.easeInOut,
//               width: isSelected ? 54.w : 48.w,
//               height: isSelected ? 54.h : 48.h,
//               child: ColorFiltered(
//                 colorFilter: isSelected
//                     ? const ColorFilter.mode(
//                         Colors.transparent, // 원래 색 (필터 없음)
//                         BlendMode.multiply,
//                       )
//                     : const ColorFilter.matrix(<double>[
//                         0.2126, 0.7152, 0.0722, 0, 0, // R
//                         0.2126, 0.7152, 0.0722, 0, 0, // G
//                         0.2126, 0.7152, 0.0722, 0, 0, // B
//                         0, 0, 0, 1, 0, // A
//                       ]),
//                 child: Image.asset(imagePath),
//               ),
//             ),
//             if (isSelected)
//               Positioned(
//                 bottom: -37.h,
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                       color: AppColors.white,
//                       border:
//                           Border.all(color: AppColors.orange200, width: 2.r),
//                       borderRadius: BorderRadius.circular(20.r)),
//                   child: Center(
//                     child: Text(
//                       emotionLabel,
//                       style: AppFontStyles.bodyRegular12.copyWith(
//                         color: AppColors.grey900,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ]),
//     );
//   }
// }
