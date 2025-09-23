import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/onboarding/widgets/select_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectAiPersonality extends ConsumerStatefulWidget {
  const SelectAiPersonality({
    super.key,
  });

  @override
  ConsumerState<SelectAiPersonality> createState() =>
      _SelectAiPersonalityState();
}

class _SelectAiPersonalityState
    extends ConsumerState<SelectAiPersonality> {
  int _selectedIndex = -1;

  final _personalities = [
    '차분하게 상황을 분석하고 문제를 해결하는 친구',
    '감정 표현이 풍부하고 따뜻한 친구',
    '어딘가 엉뚱하지만 마음만은 따뜻한 친구',
    '따뜻함과 이성적인 사고를 모두 가진 친구'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 24.r,
        ),
        Container(
          width: double.infinity,
          height: 94.h,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '캐릭터의 성격을\n골라볼까요?',
              style: AppFontStyles.heading2
                  .copyWith(color: AppColors.grey900),
            ),
          ),
        ),
        SizedBox(
          height: 24.r,
        ),
        Column(
          children: List.generate(
            _personalities.length,
            (index) {
              final isSelected = _selectedIndex == index;
              return Column(
                children: [
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex =
                              (_selectedIndex == index)
                                  ? -1
                                  : index;
                        });
                        ref
                            .read(userViewModelProvider.notifier)
                            .setAiPersonality(
                                check: _selectedIndex != -1,
                                aiPersonality:
                                    _personalities[index]);
                      },
                      child: SelectBox(
                          isSelected: isSelected,
                          text: _personalities[index])),
                  _personalities.length - 1 == index
                      ? SizedBox.shrink()
                      : SizedBox(
                          height: 8.h,
                        )
                ],
              );
            },
          ),
        ),
        Spacer(),
        Align(
            alignment: Alignment.bottomRight,
            child: Image.asset(
              'assets/images/cado_profile.png',
              width: 120.w,
              height: 180.h,
            )),
      ],
    );
  }
}
