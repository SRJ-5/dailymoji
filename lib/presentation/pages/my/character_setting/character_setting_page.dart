import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/character_box.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/my/widgets/edit_nickname_card.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CharacterSettingPage extends ConsumerStatefulWidget {
  const CharacterSettingPage({super.key});

  @override
  ConsumerState<CharacterSettingPage> createState() => _CharacterSettingPageState();
}

class _CharacterSettingPageState extends ConsumerState<CharacterSettingPage> {
  PageController pageController = PageController(initialPage: 0, viewportFraction: 0.75);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {}); // 첫 빌드 이후 pageController.page 값이 정확히 들어옴
    });
  }

  void selectCharacter({required int selectNum, required String aiPersonality}) {
    ref.read(userViewModelProvider.notifier).setAiPersonality(selectNum: selectNum, aiPersonality: aiPersonality);
  }

  final _personalitiesOnboarding = CharacterPersonality.values.map((e) => e.onboardingLabel).toList();

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userViewModelProvider);
    final userViewModel = ref.read(userViewModelProvider.notifier);

    final double viewportFraction = pageController.viewportFraction;

    int _selectedIndex = userState.characterNum;

    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        centerTitle: true,
        title: AppText(
          AppTextStrings.characterSettings,
          style: AppFontStyles.bodyBold18.copyWith(color: AppColors.grey900),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              NicknameEditCard(nickname: userState.userProfile!.characterNm!, isUser: false),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.only(top: 16.h, left: 16.w),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.grey100,
                      width: 1,
                    ),
                  ),
                ),
                child: AppText(
                  AppTextStrings.characterSelect,
                  style: AppFontStyles.bodyBold14.copyWith(color: AppColors.grey900),
                ),
              ),
              SizedBox(height: 30.h),
              SizedBox(
                height: 440.h,
                // width: double.infinity,
                child: OverflowBox(
                  child: PageView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: pageController,
                    clipBehavior: Clip.none,
                    itemCount: AppImages.characterListProfile.length,
                    itemBuilder: (context, index) {
                      // ✨ 1. AnimatedBuilder로 감싸기
                      return AnimatedBuilder(
                        animation: pageController,
                        builder: (context, child) {
                          double scale = 1.0;
                          // pageController.page가 초기화되었는지 확인
                          if (pageController.position.haveDimensions) {
                            // ✨ 2. 현재 페이지 위치와 아이템 인덱스의 차이 계산
                            final page = pageController.page!;
                            final difference = (page - index).abs();

                            // ✨ 3. 차이에 따라 scale 값 계산 (1.0에서 0.8 사이로)
                            // 중앙(difference=0)일 때 1.0, 한 페이지 떨어졌을때(difference=1) 0.8
                            scale = 1.0 - (difference * 0.2);
                            scale = scale.clamp(0.75, 1.0); // 최소/최대 크기 제한
                          }

                          // ✨ 4. Transform.scale로 크기 적용
                          return Transform.scale(
                            scale: scale,
                            child: Align(
                              // Align은 그대로 유지하여 중앙 정렬
                              alignment: Alignment.center,
                              child: CharacterBox(
                                viewportFraction: viewportFraction,
                                personality: _personalitiesOnboarding[index],
                                characterImage: AppImages.characterListProfile[index],
                                onSelect: selectCharacter,
                                isOnboarding: false,
                                index: index,
                              ), // 원래의 캐릭터 박스 위젯
                            ),
                          );
                        },
                      );

                      // Align(
                      //     alignment: Alignment.center,
                      //     child: character_box());
                    },
                  ),
                ),
              )

              /*
              GestureDetector(
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (context) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          Positioned(
                            // left: 183.w,
                            top: 216.h,
                            right: 12.w,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                width: 182.w,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: AppColors.grey100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF1D293D).withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: CharacterPersonality.values.map((e) {
                                    final isSelected = userState.userProfile!.characterPersonality! == e.myLabel;
                                    return GestureDetector(
                                      onTap: () => Navigator.pop(context, e.myLabel),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              isSelected ? AppIcons.radioSelected : AppIcons.radioUnselected,
                                              width: 16.r,
                                              height: 16.r,
                                            ),
                                            SizedBox(width: 8.w),
                                            AppText(
                                              e.myLabel,
                                              style: isSelected
                                                  ? AppFontStyles.bodySemiBold14.copyWith(
                                                      color: AppColors.grey900,
                                                    )
                                                  : AppFontStyles.bodyRegular14.copyWith(
                                                      color: AppColors.grey900,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (result != null) {
                    ref.read(userViewModelProvider.notifier).updateCharacterPersonality(newCharacterPersonality: result);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: Row(
                    children: [
                      AppText(
                        "캐릭터 성격",
                        style: AppFontStyles.bodyRegular16.copyWith(
                          color: AppColors.grey700,
                        ),
                      ),
                      Spacer(),
                      AppText(
                        userState.userProfile!.characterPersonality!,
                        style: AppFontStyles.bodyRegular14.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                        width: 24.w,
                        height: 24.h,
                        child: SvgPicture.asset(
                          AppIcons.unfoldMore,
                          colorFilter: ColorFilter.mode(AppColors.grey700, BlendMode.srcIn),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            */
            ],
          ),
        ),
      ),
    );
  }
}
