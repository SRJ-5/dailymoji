import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/part1/character_box.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectAiPersonality extends ConsumerStatefulWidget {
  final Function(
      {required int selectNum,
      required String aiPersonality}) onSelect;
  SelectAiPersonality({super.key, required this.onSelect});

  @override
  ConsumerState<SelectAiPersonality> createState() =>
      _SelectAiPersonalityState();
}

class _SelectAiPersonalityState
    extends ConsumerState<SelectAiPersonality> {
  int _selectedIndex = 0;

  PageController pageController =
      PageController(initialPage: 0, viewportFraction: 0.75);

  final _personalitiesOnboarding = CharacterPersonality.values
      .map((e) => e.onboardingLabel)
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {}); // 첫 빌드 이후 pageController.page 값이 정확히 들어옴
    });
    _selectedIndex = ref.read(userViewModelProvider).step11;
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double viewportFraction =
        pageController.viewportFraction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 16.r,
        ),
        Container(
          width: double.infinity,
          height: 88.h,
          padding: EdgeInsets.symmetric(
              horizontal: 4.w, vertical: 8.h),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              '마음에 드는 도우미를\n골라볼까요?',
              style: AppFontStyles.heading2
                  .copyWith(color: AppColors.grey900),
            ),
          ),
        ),
        SizedBox(
          height: 40.r,
        ),
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
                      scale =
                          scale.clamp(0.75, 1.0); // 최소/최대 크기 제한
                    }

                    // ✨ 4. Transform.scale로 크기 적용
                    return Transform.scale(
                      scale: scale,
                      child: Align(
                        // Align은 그대로 유지하여 중앙 정렬
                        alignment: Alignment.center,
                        child: CharacterBox(
                          viewportFraction: viewportFraction,
                          personality:
                              _personalitiesOnboarding[index],
                          characterImage: AppImages
                              .characterListProfile[index],
                          onSelect: widget.onSelect,
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

        // Column(
        //   children: List.generate(
        //     _personalitiesOnboarding.length,
        //     (index) {
        //       final isSelected = _selectedIndex == index;
        //       return Column(
        //         children: [
        //           GestureDetector(
        //               onTap: () {
        //                 setState(() {
        //                   _selectedIndex =
        //                       (_selectedIndex == index)
        //                           ? -1
        //                           : index;
        //                 });
        //                 ref
        //                     .read(
        //                         userViewModelProvider.notifier)
        //                     .setAiPersonality(
        //                         selectNum: _selectedIndex,
        //                         aiPersonality:
        //                             _personalitiesMy[index]);
        //               },
        //               child: SelectBox(
        //                   isSelected: isSelected,
        //                   text: _personalitiesOnboarding[
        //                       index])),
        //           _personalitiesOnboarding.length - 1 == index
        //               ? SizedBox.shrink()
        //               : SizedBox(
        //                   height: 8.h,
        //                 )
        //         ],
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }
}
