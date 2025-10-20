import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailymoji/presentation/providers/background_provider.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 배경 선택 페이지 (1번 시안 스타일)
class BackgroundSettingPage extends ConsumerStatefulWidget {
  const BackgroundSettingPage({super.key});

  @override
  ConsumerState<BackgroundSettingPage> createState() =>
      _BackgroundSelectPageState();
}

class _BackgroundSelectPageState extends ConsumerState<BackgroundSettingPage> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentIndex = 0;

  // 사용할 배경 리스트
  final List<String> backgrounds = [
    AppImages.bgHouse,
    AppImages.bgRain,
    AppImages.bgSnow,
    AppImages.bgForest,
  ];

  @override
  Widget build(BuildContext context) {
    final bgState = ref.watch(backgroundImageProvider); // ✅ 현재 상태 읽기
    final bgNotifier = ref.read(backgroundImageProvider.notifier);
    // 캐릭터 프로바이더
    final selectedCharacterNum =
        ref.read(userViewModelProvider).userProfile!.characterNum;

    return Scaffold(
      // ✅ AppBar 영역 뒤까지 바디를 연장 → 이미지가 상단까지 깔림
      extendBodyBehindAppBar: true,

      // ✅ AppBar: 가운데 타이틀 + 기본 back (1번 시안처럼)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // 상태바 아이콘 색(배경 밝아 어두운 아이콘)
        title: Text(
          AppTextStrings.backgroundSetting,
          style: AppFontStyles.heading3.copyWith(color: AppColors.grey900),
        ),
        // leading 은 기본 back 버튼으로 충분
      ),

      // 바디는 이미지가 꽉 차도록 Stack 사용
      body: Stack(
        children: [
          // ✅ 전체 페이지 뷰 (배경 미리보기)
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: backgrounds.length,
            itemBuilder: (context, index) {
              final path = backgrounds[index];
              return Image.asset(
                path,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // ✅ 좌/우 화살표 (가운데 정렬)
          // 터치 영역 확실히 잡히도록 IconButton + constraints
          // ✅ 좌우 화살표 버튼
          if (_currentIndex != 0)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_currentIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: SizedBox(
                  height: 52.h,
                  width: 52.w,
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.grey900,
                  ),
                ),
              ),
            ),

          if (_currentIndex != backgrounds.length - 1)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_currentIndex < backgrounds.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: SizedBox(
                  height: 52.h,
                  width: 52.w,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.grey900,
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.center,
            child: Image.asset(
              AppImages.characterListProfile[selectedCharacterNum!],
              height: 168.h,
              width: 156.w,
            ),
          ),

          // ✅ 하단: 인디케이터 + “선택하기” 버튼 (Column으로 한 번에 배치)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: EdgeInsets.only(bottom: 20.h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 인디케이터 (1번 시안 스타일: 작은 점 4개)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        backgrounds.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? AppColors.grey900 // 활성 점
                                : AppColors.grey100, // 비활성 점
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // 선택이 됐을 때 : 안됐을 때
                    bgState != backgrounds[_currentIndex]
                        ? Container(
                            width: double.infinity,
                            height: 48.h,
                            margin: EdgeInsets.symmetric(horizontal: 12.w)
                                .copyWith(bottom: 52.h),
                            child: ElevatedButton(
                              onPressed: () async {
                                final selectedPath = backgrounds[_currentIndex];
                                // 토스트 메시지 표시
                                ToastHelper.showToast(
                                  context,
                                  message: AppTextStrings.backgroundDone,
                                );
                                await bgNotifier.setBackground(selectedPath);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green500,
                                disabledBackgroundColor: AppColors.green200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                AppTextStrings.backgroundSelect,
                                style: AppFontStyles.bodyMedium16
                                    .copyWith(color: AppColors.grey50),
                              ),
                            ),
                          )
                        : Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: 48.h,
                            margin: EdgeInsets.symmetric(horizontal: 12.w)
                                .copyWith(bottom: 52.h),
                            decoration: BoxDecoration(
                              color: AppColors.green700,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: AppColors.green200, width: 2.r),
                            ),
                            child: Text(
                              AppTextStrings.backgroundSelected,
                              style: AppFontStyles.bodyMedium16
                                  .copyWith(color: AppColors.grey50),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
